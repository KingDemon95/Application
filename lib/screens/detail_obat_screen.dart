import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'atur_pengingat_screen.dart';

class DetailObatScreen extends StatefulWidget {
  final Map<String, dynamic> rekomendasiData;
  final int usiaBulan;

  const DetailObatScreen({
    super.key,
    required this.rekomendasiData,
    required this.usiaBulan,
  });

  @override
  State<DetailObatScreen> createState() => _DetailObatScreenState();
}

class _DetailObatScreenState extends State<DetailObatScreen> {
  Map<String, dynamic>? _detailObat;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetailObat();
  }

  Future<void> _fetchDetailObat() async {
    final obatId = widget.rekomendasiData['obatId'] as String?;
    if (obatId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('obat')
          .doc(obatId)
          .get();
      setState(() {
        _detailObat = doc.data();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rek = widget.rekomendasiData;
    final namaObat = _detailObat?['namaObat'] ?? rek['obatId'] ?? '-';
    final dosisAturan = rek['dosisAturanPakai'] as String? ?? '-';
    final frekuensi = rek['frekuensiPerHari'] as int? ?? 1;
    final intervalJam = rek['intervalJam'] as int? ?? (24 ~/ frekuensi);
    final rentangUsia = rek['rentangUsia'] as String? ?? '-';
    final bisaReminder = rek['bisaReminder'] as bool? ?? true;

    final infoAlergi = _detailObat?['infoAlergi'] as String? ?? '-';
    final infoPenyakit = _detailObat?['infoPenyakitKronis'] as String? ?? '-';
    final infoHamil = _detailObat?['infoHamil'] as String? ?? '-';
    final infoMenyusui = _detailObat?['infoMenyusui'] as String? ?? '-';

    final isHerbal = _detailObat?['jenisRekomendasi'] == 'herbal';

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
          namaObat,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.vx.textDark,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Header obat
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
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
                                    color: isHerbal
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : context.vx.chipTeal,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    isHerbal
                                        ? Icons.eco_outlined
                                        : Icons.medication_outlined,
                                    color: isHerbal
                                        ? Colors.green
                                        : context.vx.primary,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        namaObat,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: context.vx.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isHerbal ? 'Herbal' : 'Tablet / Sirup',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: context.vx.textMedium,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Untuk usia $rentangUsia',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: context.vx.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Detail info
                          _DetailSection(
                            children: [
                              _DetailItem(
                                icon: Icons.calculate_outlined,
                                title: 'Dosis sesuai perhitungan',
                                desc: dosisAturan,
                              ),
                              _Divider(),
                              _DetailItem(
                                icon: Icons.warning_amber_rounded,
                                title: 'Alergi',
                                desc: infoAlergi == '-'
                                    ? 'Tidak ada info alergi obat yang terdeteksi.'
                                    : 'Hati-hati: $infoAlergi',
                              ),
                              _Divider(),
                              _DetailItem(
                                icon: Icons.favorite_border_rounded,
                                title: 'Penyakit / komorbid',
                                desc: infoPenyakit == '-'
                                    ? 'Tidak ada kondisi khusus yang teridentifikasi.'
                                    : infoPenyakit,
                              ),
                              _Divider(),
                              _DetailItem(
                                icon: Icons.schedule_rounded,
                                title: 'Aturan konsumsi obat',
                                desc:
                                    'Dikonsumsi ${frekuensi}x sehari, setiap $intervalJam jam sekali.',
                              ),
                              _Divider(),
                              _DetailItem(
                                icon: Icons.info_outline_rounded,
                                title: 'Kewaspadaan',
                                desc:
                                    'Simpan dengan kondisi kering dan sejuk, jauhkan dari jangkauan anak kecil.',
                              ),
                              if (infoHamil.isNotEmpty && infoHamil != '-') ...[
                                _Divider(),
                                _DetailItem(
                                  icon: Icons.pregnant_woman_rounded,
                                  title: 'Ibu hamil & menyusui',
                                  desc:
                                      'Hamil: $infoHamil. Menyusui: $infoMenyusui',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tombol atur pengingat
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    color: context.vx.surface,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: bisaReminder
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AturPengingatScreen(
                                      rekomendasiData: widget.rekomendasiData,
                                      namaObat: namaObat,
                                      frekuensiPerHari: frekuensi,
                                      intervalJam: intervalJam,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.vx.primary,
                          disabledBackgroundColor: context.vx.inputBorder,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Atur Pengingat Obat',
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

class _DetailSection extends StatelessWidget {
  final List<Widget> children;
  const _DetailSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.vx.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.vx.cardBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _DetailItem({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.vx.chipTeal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: context.vx.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.vx.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.vx.textMedium,
                    height: 1.5,
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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.vx.cardBorder,
      indent: 16,
      endIndent: 16,
    );
  }
}