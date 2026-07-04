import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pengingat_model.dart';
import '../services/pengingat_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class PengingatDetailScreen extends StatefulWidget {
  final String pengingatId;
  final String namaObat; // dari notif payload (fallback)

  const PengingatDetailScreen({
    super.key,
    required this.pengingatId,
    required this.namaObat,
  });

  @override
  State<PengingatDetailScreen> createState() => _PengingatDetailScreenState();
}

class _PengingatDetailScreenState extends State<PengingatDetailScreen> {
  final _service = PengingatService();
  final _notifService = NotificationService();

  PengingatModel? _pengingat;
  bool _loading = true;
  bool _sudahMunculWarning = false; // agar popup hari ke-3 hanya muncul sekali

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getPengingat(widget.pengingatId);
    if (!mounted) return;
    setState(() {
      _pengingat = data;
      _loading = false;
    });

    // Setelah data loaded, cek apakah sudah 3 hari
    if (data != null && data.sudah3Hari && !_sudahMunculWarning) {
      _sudahMunculWarning = true;
      // Delay sedikit biar build selesai dulu
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showWarning3Hari(data);
      });
    }
  }

  // ─── Popup Warning Hari ke-3 ─────────────────────────────────────────────
  void _showWarning3Hari(PengingatModel p) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade600, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'Kamu sudah menggunakan obat ini\nselama ${p.hariPenggunaanDihitung} hari.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.vx.textDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Jika keluhan belum membaik, jangan lanjutkan penggunaan tanpa pertimbangan tenaga kesehatan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: context.vx.textMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.vx.primary,
                        side: BorderSide(color: context.vx.primary),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Saya sudah membaik',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);                       
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Segera konsultasi ke tenaga kesehatan.',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            backgroundColor: context.vx.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.vx.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Lihat saran',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Konfirmasi Sudah Minum ───────────────────────────────────────────────
  Future<void> _onSudahMinum() async {
    final p = _pengingat;
    if (p == null) return;

    // Catat ke Firestore
    await _service.sudahMinum(p.id);

    // Reschedule notif selanjutnya (opsional — karena sudah repeat daily)
    // Notifikasi harian otomatis sudah berjalan, jadi tidak perlu reschedule manual
    // Tapi bisa update badge / status

    if (!mounted) return;

    // Reload data + tampilkan feedback
    _loadData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tercatat! Jadwal berikutnya pukul ${p.jadwalBerikutnya ?? '-'}',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: context.vx.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── Konfirmasi Hentikan ──────────────────────────────────────────────────
  void _onHentikan() {
    final p = _pengingat;
    if (p == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_off_outlined,
                    color: Colors.red.shade400, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Hentikan pengingat obat ini?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.vx.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pengingat untuk ${p.namaObat} tidak akan dikirim lagi. '
                'Pastikan keluhanmu sudah membaik atau penggunaan obat memang sudah selesai.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: context.vx.textMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade400, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bila keluhan tidak membaik, segera konsultasikan ke tenaga kesehatan.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.vx.textMedium,
                        side: BorderSide(color: context.vx.inputBorder),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Kembali',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _service.hentikanPengingat(p.id);
                        // Batalkan semua notifikasi untuk obat ini
                        await _notifService.batalkanPengingat(
                          baseId: PengingatService.generateBaseId(p.id),
                          jumlah: p.frekuensiPerHari + 2,
                        );
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Ya, Hentikan',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.vx.background,
        appBar: _buildAppBar('Pengingat Obat'),
        body: Center(
          child: CircularProgressIndicator(color: context.vx.primary),
        ),
      );
    }

    final p = _pengingat;
    if (p == null) {
      return Scaffold(
        backgroundColor: context.vx.background,
        appBar: _buildAppBar('Pengingat Obat'),
        body: Center(
          child: Text(
            'Data pengingat tidak ditemukan.',
            style: GoogleFonts.poppins(
                color: context.vx.textMedium, fontSize: 14),
          ),
        ),
      );
    }

    // Cek apakah baru saja minum (dalam 30 menit terakhir)
    final baruMinum = p.terakhirDiminum != null &&
        DateTime.now().difference(p.terakhirDiminum!).inMinutes <= 30;

    return Scaffold(
      backgroundColor: context.vx.background,
      appBar: _buildAppBar('Pengingat Obat'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Banner "Baru Minum" ─────────────────────────
                  if (baruMinum) ...[
                    _BannerSudahDiminum(
                      jadwalBerikutnya: p.jadwalBerikutnya ?? '-',
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── Header Obat ─────────────────────────────────
                  _ObatHeader(pengingat: p),
                  const SizedBox(height: 16),

                  // ─── Info Singkat ─────────────────────────────────
                  _InfoSingkat(pengingat: p),
                  const SizedBox(height: 20),

                  // ─── Jadwal Minum ─────────────────────────────────
                  Text(
                    'Jadwal Minum Obat',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.vx.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...p.jadwalLengkap.asMap().entries.map(
                        (e) => _JadwalItem(
                          urutan: e.key + 1,
                          jam: e.value,
                          dosis: p.dosisAturanPakai,
                          isSaatIni: p.isJadwalSaatIni(e.value),
                          sudahDiminum: baruMinum &&
                              p.isJadwalSaatIni(e.value),
                        ),
                      ),

                  const SizedBox(height: 20),

                  // ─── Informasi Obat (Accordion) ───────────────────
                  Text(
                    'Informasi Obat',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.vx.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AkordeonInfo(
                    title: 'Penjelasan',
                    icon: Icons.info_outline,
                    content:
                        '${p.namaObat} digunakan untuk meringankan gejala ${p.penyakitId}. Gunakan sesuai dosis yang dianjurkan.',
                  ),
                  _AkordeonInfo(
                    title: 'Peringatan',
                    icon: Icons.warning_amber_outlined,
                    iconColor: Colors.orange,
                    content:
                        'Jangan melebihi dosis yang dianjurkan. Hindari penggunaan bersamaan dengan produk lain yang mengandung bahan aktif serupa.',
                  ),
                  _AkordeonInfo(
                    title: 'Catatan Penggunaan',
                    icon: Icons.notes_outlined,
                    content:
                        'Telan tablet dengan air putih. Gunakan sesuai aturan pakai.',
                    isLast: true,
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ─── Tombol Bawah ────────────────────────────────────────
          Container(
            color: context.vx.surface,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onSudahMinum,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.vx.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Sudah Minum',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _onHentikan,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.vx.textMedium,
                      side: BorderSide(color: context.vx.inputBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Hentikan Pengingat Obat',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.vx.textMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(String title) {
    return AppBar(
      backgroundColor: context.vx.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: context.vx.textDark,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined,
              color: context.vx.textMedium),
          onPressed: () {},
        ),
      ],
    );
  }
}

// ─── Banner Sudah Diminum ─────────────────────────────────────────────────────
class _BannerSudahDiminum extends StatelessWidget {
  final String jadwalBerikutnya;
  const _BannerSudahDiminum({required this.jadwalBerikutnya});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: Colors.green.shade500, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Obat berhasil dicatat.\nSudah diminum. Jadwal berikutnya pukul $jadwalBerikutnya',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.green.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header Obat ──────────────────────────────────────────────────────────────
class _ObatHeader extends StatelessWidget {
  final PengingatModel pengingat;
  const _ObatHeader({required this.pengingat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.vx.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.vx.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.vx.chipTeal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.medication_rounded,
                color: context.vx.primary, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pengingat.namaObat,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.vx.textDark,
                  ),
                ),
                Text(
                  'Tablet',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: context.vx.textMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.vx.chipTeal,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Hari ke-${pengingat.hariPenggunaanDihitung}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: context.vx.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Singkat (3 baris) ───────────────────────────────────────────────────
class _InfoSingkat extends StatelessWidget {
  final PengingatModel pengingat;
  const _InfoSingkat({required this.pengingat});

  @override
  Widget build(BuildContext context) {
    final berikutnya = pengingat.jadwalBerikutnya;
    final label = berikutnya != null
        ? 'Hari ini, pukul $berikutnya'
        : 'Sudah selesai hari ini';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.vx.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.vx.cardBorder),
      ),
      child: Column(
        children: [
          _InfoRow(
              label: 'Dosis saat ini',
              value: pengingat.dosisAturanPakai),
          Divider(height: 16, color: context.vx.cardBorder),
          _InfoRow(label: 'Aturan pakai saat ini', value: 'Setelah makan'),
          Divider(height: 16, color: context.vx.cardBorder),
          _InfoRow(label: 'Jadwal berikutnya', value: label),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 13, color: context.vx.textMedium),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.vx.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Item Jadwal ──────────────────────────────────────────────────────────────
class _JadwalItem extends StatelessWidget {
  final int urutan;
  final String jam;
  final String dosis;
  final bool isSaatIni;
  final bool sudahDiminum;

  const _JadwalItem({
    required this.urutan,
    required this.jam,
    required this.dosis,
    required this.isSaatIni,
    required this.sudahDiminum,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = context.vx.surface;
    Color borderColor = context.vx.cardBorder;
    String statusLabel = 'Akan datang';

    if (sudahDiminum) {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade200;
      statusLabel = 'Sudah diminum';
    } else if (isSaatIni) {
      bgColor = context.vx.chipTeal;
      borderColor = context.vx.primary;
      statusLabel = 'Saat ini';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Jam
          SizedBox(
            width: 52,
            child: Text(
              jam,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.vx.textDark,
              ),
            ),
          ),
          // Dosis singkat
          Expanded(
            child: Text(
              dosis.split(',').first, // ambil info pertama saja
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: context.vx.textMedium,
              ),
            ),
          ),
          // Aturan makan
          Text(
            'Setelah makan',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: context.vx.textLight,
            ),
          ),
          const SizedBox(width: 8),
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: sudahDiminum
                  ? Colors.green.shade100
                  : isSaatIni
                      ? context.vx.primary
                      : context.vx.inputFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sudahDiminum)
                  Icon(Icons.check_circle_rounded,
                      color: Colors.green.shade600, size: 12),
                if (!sudahDiminum)
                  Icon(
                    isSaatIni
                        ? Icons.access_time_rounded
                        : Icons.schedule_rounded,
                    color: isSaatIni ? Colors.white : context.vx.textLight,
                    size: 12,
                  ),
                const SizedBox(width: 3),
                Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: sudahDiminum
                        ? Colors.green.shade700
                        : isSaatIni
                            ? Colors.white
                            : context.vx.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Akordeon Info ────────────────────────────────────────────────────────────
class _AkordeonInfo extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final String content;
  final bool isLast;

  const _AkordeonInfo({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.content,
    this.isLast = false,
  });

  @override
  State<_AkordeonInfo> createState() => _AkordeonInfoState();
}

class _AkordeonInfoState extends State<_AkordeonInfo> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 8),
      decoration: BoxDecoration(
        color: context.vx.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.vx.cardBorder),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.iconColor ?? context.vx.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.vx.textDark,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: context.vx.textLight,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(44, 0, 16, 14),
              child: Text(
                widget.content,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: context.vx.textMedium,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}