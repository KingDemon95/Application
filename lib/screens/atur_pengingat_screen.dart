import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../services/pengingat_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class AturPengingatScreen extends StatefulWidget {
  final Map<String, dynamic> rekomendasiData;
  final String namaObat;
  final int frekuensiPerHari;
  final int intervalJam;

  const AturPengingatScreen({
    super.key,
    required this.rekomendasiData,
    required this.namaObat,
    required this.frekuensiPerHari,
    required this.intervalJam,
  });

  @override
  State<AturPengingatScreen> createState() => _AturPengingatScreenState();
}

class _AturPengingatScreenState extends State<AturPengingatScreen> {
  int _jamPertama = 8;
  int _menitPertama = 0;
  bool _simpanLoading = false;

  // ─── Hitung semua jadwal dari jam pertama + interval ─────────────────────
  List<Map<String, dynamic>> get _jadwalMinum {
    final list = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.frekuensiPerHari; i++) {
      final totalMenit =
          (_jamPertama * 60 + _menitPertama) + (i * widget.intervalJam * 60);
      final jam = (totalMenit ~/ 60) % 24;
      final menit = totalMenit % 60;
      list.add({
        'urutan': i + 1,
        'jam': jam,
        'menit': menit,
        'tambahJam':
            i == 0 ? null : '+ ${i * widget.intervalJam} jam kemudian',
      });
    }
    return list;
  }

  String _formatWaktu(int jam, int menit) =>
      '${jam.toString().padLeft(2, '0')}:${menit.toString().padLeft(2, '0')}';

  String get _labelFrekuensi => '${widget.frekuensiPerHari}x sehari';

  // ─── Simpan pengingat ke Firestore + jadwalkan notifikasi ────────────────
  Future<void> _simpanPengingat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('Kamu harus login terlebih dahulu');
      return;
    }

    setState(() => _simpanLoading = true);

    try {
      final jadwal = _jadwalMinum;

      // Format jadwal ke List<String> "HH:mm"
      final jadwalString = jadwal
          .map((j) => _formatWaktu(j['jam'] as int, j['menit'] as int))
          .toList();

      // 1. Simpan ke Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pengingat')
          .add({
        ...widget.rekomendasiData, // data dari rekomendasi (obatId, penyakitId, dll)
        'namaObat': widget.namaObat,
        'frekuensiPerHari': widget.frekuensiPerHari,
        'intervalJam': widget.intervalJam,
        'jamPertama': _formatWaktu(_jamPertama, _menitPertama),
        'jadwalLengkap': jadwalString,
        'isAktif': true,
        'hariPenggunaan': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final pengingatId = docRef.id;

      // 2. Jadwalkan notifikasi lokal
      final jadwalNotif = jadwal
          .map((j) => {
                'urutan': j['urutan'] as int,
                'jam': j['jam'] as int,
                'menit': j['menit'] as int,
              })
          .toList();

      await NotificationService().jadwalkanPengingat(
        baseId: PengingatService.generateBaseId(pengingatId),
        pengingatId: pengingatId,
        namaObat: widget.namaObat,
        jadwal: jadwalNotif,
      );

      if (!mounted) return;

      // 3. Success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: context.vx.chipTeal,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    color: context.vx.primary, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'Pengingat Disimpan!',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.vx.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kamu akan diingatkan minum ${widget.namaObat} sesuai jadwal.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: context.vx.textMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HomeScreen()),
                      (_) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.vx.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Kembali ke Beranda',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) _showError('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _simpanLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: Colors.red.shade500,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Bottom sheet time picker pakai CupertinoPicker ──────────────────────
  void _showTimePicker() {
    int tempJam = _jamPertama;
    int tempMenit = _menitPertama;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.vx.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.vx.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: context.vx.textMedium),
                    ),
                  ),
                  Text(
                    'Pilih Jam',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.vx.textDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _jamPertama = tempJam;
                        _menitPertama = tempMenit;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      'Selesai',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.vx.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Picker jam
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                          initialItem: _jamPertama),
                      itemExtent: 44,
                      onSelectedItemChanged: (val) => tempJam = val,
                      children: List.generate(
                        24,
                        (i) => Center(
                          child: Text(
                            i.toString().padLeft(2, '0'),
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: context.vx.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    ':',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: context.vx.textDark,
                    ),
                  ),
                  // Picker menit
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                          initialItem: _menitPertama),
                      itemExtent: 44,
                      onSelectedItemChanged: (val) => tempMenit = val,
                      children: List.generate(
                        60,
                        (i) => Center(
                          child: Text(
                            i.toString().padLeft(2, '0'),
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: context.vx.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final jadwal = _jadwalMinum;

    return Scaffold(
      backgroundColor: context.vx.background,
      appBar: AppBar(
        backgroundColor: context.vx.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Atur Jam Minum Pertama',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.vx.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Info Obat ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.vx.chipTeal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.medication_outlined,
                              color: context.vx.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.namaObat,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.vx.primary,
                                  ),
                                ),
                                Text(
                                  _labelFrekuensi,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                        color: context.vx.primary
                                          .withValues(alpha: (0.7 * 255).round().toDouble()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Pilih jam minum pertama',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: context.vx.textMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Setiap ${widget.intervalJam} jam sekali',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: context.vx.textLight,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ─── Display Jam ────────────────────────────────
                    GestureDetector(
                      onTap: _showTimePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: context.vx.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: context.vx.primary, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _TimeBox(
                              value: _jamPertama
                                  .toString()
                                  .padLeft(2, '0'),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                ':',
                                style: GoogleFonts.poppins(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: context.vx.textDark,
                                ),
                              ),
                            ),
                            _TimeBox(
                              value: _menitPertama
                                  .toString()
                                  .padLeft(2, '0'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: _showTimePicker,
                        icon: Icon(Icons.edit_rounded,
                            size: 14, color: context.vx.primary),
                        label: Text(
                          'Ubah waktu',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: context.vx.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── Jadwal Otomatis ────────────────────────────
                    Text(
                      'Waktu minum berikutnya (otomatis)',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.vx.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...jadwal.map(
                      (j) => _JadwalItem(
                        urutan: j['urutan'] as int,
                        waktu: _formatWaktu(
                            j['jam'] as int, j['menit'] as int),
                        tambahJam: j['tambahJam'] as String?,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.vx.chipTeal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.loop_rounded,
                              size: 16, color: context.vx.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pengingat akan berulang setiap hari sesuai jadwal di atas.',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: context.vx.primary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Tombol Simpan ────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              color: context.vx.surface,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _simpanLoading ? null : _simpanPengingat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.vx.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _simpanLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Simpan Pengingat',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Time Box ─────────────────────────────────────────────────────────────────
class _TimeBox extends StatelessWidget {
  final String value;
  const _TimeBox({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.vx.chipTeal,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: context.vx.primary,
          height: 1,
        ),
      ),
    );
  }
}

// ─── Jadwal Item ──────────────────────────────────────────────────────────────
class _JadwalItem extends StatelessWidget {
  final int urutan;
  final String waktu;
  final String? tambahJam;

  const _JadwalItem({
    required this.urutan,
    required this.waktu,
    this.tambahJam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.vx.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urutan == 1 ? context.vx.primary : context.vx.cardBorder,
          width: urutan == 1 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: urutan == 1 ? context.vx.primary : context.vx.chipTeal,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$urutan',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: urutan == 1 ? Colors.white : context.vx.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            waktu,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.vx.textDark,
            ),
          ),
          const Spacer(),
          if (tambahJam == null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.vx.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'jam pertama',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.vx.primary,
                ),
              ),
            )
          else
            Text(
              tambahJam!,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: context.vx.textLight,
              ),
            ),
        ],
      ),
    );
  }
}