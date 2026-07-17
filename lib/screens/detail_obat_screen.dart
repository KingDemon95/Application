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

  // Mapping golonganObat -> asset gambar logo (sama seperti hasil rekomendasi)
  String? get _logoAsset {
    final golongan = _detailObat?['golonganObat'] as String?;
    switch (golongan) {
      case 'bebas':
        return 'assets/images/bebas.png';
      case 'bebas_terbatas':
        return 'assets/images/bebas_terbatas.png';
      case 'herbal':
        return 'assets/images/herbal.png';
      default:
        return null;
    }
  }

  String get _labelJenis {
    final golongan = _detailObat?['golonganObat'] as String?;
    switch (golongan) {
      case 'bebas':
        return 'Obat Bebas';
      case 'bebas_terbatas':
        return 'Obat Bebas Terbatas';
      case 'herbal':
        return 'Herbal';
      default:
        return 'Tablet / Sirup';
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

    final logoAsset = _logoAsset;

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── Header obat ───────────────────────────
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
                                    color: context.vx.chipTeal,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: logoAsset != null
                                      ? Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Image.asset(
                                            logoAsset,
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      : Icon(
                                          Icons.medication_outlined,
                                          color: context.vx.primary,
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
                                        _labelJenis,
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

                          const SizedBox(height: 24),

                          // ─── INFORMASI PENGGUNAAN ──────────────────
                          _SectionHeader(
                            icon: Icons.info_rounded,
                            title: 'Informasi Penggunaan',
                            color: context.vx.primary,
                          ),
                          const SizedBox(height: 12),
                          _InfoTile(
                            icon: Icons.calculate_outlined,
                            title: 'Dosis sesuai perhitungan',
                            desc: dosisAturan,
                            color: context.vx.primary,
                            bgColor: context.vx.chipTeal,
                          ),
                          const SizedBox(height: 10),
                          _InfoTile(
                            icon: Icons.schedule_rounded,
                            title: 'Aturan konsumsi obat',
                            desc:
                                'Dikonsumsi ${frekuensi}x sehari, setiap $intervalJam jam sekali.',
                            color: context.vx.primary,
                            bgColor: context.vx.chipTeal,
                          ),

                          const SizedBox(height: 24),

                          // ─── PERHATIAN ──────────────────────────────
                          _SectionHeader(
                            icon: Icons.error_rounded,
                            title: 'Perhatian',
                            color: const Color(0xFFE0942F),
                          ),
                          const SizedBox(height: 12),
                          _InfoTile(
                            icon: Icons.favorite_border_rounded,
                            title: 'Kondisi kesehatan tertentu',
                            desc: infoPenyakit == '-'
                                ? 'Tidak ada kondisi khusus yang teridentifikasi.'
                                : infoPenyakit,
                            color: const Color(0xFFE0942F),
                            bgColor: const Color(0xFFFDF1DD),
                          ),
                          const SizedBox(height: 10),
                          _InfoTile(
                            icon: Icons.info_outline_rounded,
                            title: 'Kewaspadaan',
                            desc:
                                'Simpan dengan kondisi kering dan sejuk, jauhkan dari jangkauan anak kecil.',
                            color: const Color(0xFFE0942F),
                            bgColor: const Color(0xFFFDF1DD),
                          ),

                          const SizedBox(height: 24),

                          // ─── PERINGATAN PENTING ─────────────────────
                          _SectionHeader(
                            icon: Icons.warning_rounded,
                            title: 'Peringatan Penting',
                            color: const Color(0xFFE05B4F),
                          ),
                          const SizedBox(height: 12),
                          _InfoTile(
                            icon: Icons.warning_amber_rounded,
                            title: 'Alergi',
                            desc: infoAlergi == '-'
                                ? 'Tidak ada info alergi obat yang terdeteksi.'
                                : 'Jangan gunakan obat ini apabila Anda memiliki alergi terhadap $infoAlergi.',
                            color: const Color(0xFFE05B4F),
                            bgColor: const Color(0xFFFCE6E4),
                          ),
                          if (infoHamil.isNotEmpty && infoHamil != '-') ...[
                            const SizedBox(height: 10),
                            _InfoTile(
                              icon: Icons.pregnant_woman_rounded,
                              title: 'Ibu hamil & menyusui',
                              desc:
                                  'Hamil: $infoHamil. Menyusui: $infoMenyusui',
                              color: const Color(0xFFE05B4F),
                              bgColor: const Color(0xFFFCE6E4),
                            ),
                          ],
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
                      child: ElevatedButton.icon(
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
                        label: Text(
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

// ─── Section Header (judul + garis + ikon berwarna) ───────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(color: color.withValues(alpha: 0.35), thickness: 1),
        ),
      ],
    );
  }
}

// ─── Card info dengan background tint sesuai section ───────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final Color bgColor;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
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
                const SizedBox(height: 3),
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