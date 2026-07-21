import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'detail_obat_screen.dart';
import '../widgets/pattern_background.dart';

class HasilRekomendasiScreen extends StatefulWidget {
  final String symptomId;
  final String symptomName;
  final int usiaBulan;

  const HasilRekomendasiScreen({
    super.key,
    required this.symptomId,
    required this.symptomName,
    required this.usiaBulan,
  });

  @override
  State<HasilRekomendasiScreen> createState() => _HasilRekomendasiScreenState();
}

class _HasilRekomendasiScreenState extends State<HasilRekomendasiScreen> {
  List<Map<String, dynamic>> _rekomendasi = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRekomendasi();
  }

  Future<void> _fetchRekomendasi() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rekomendasi_obat')
          .where('penyakitId', isEqualTo: widget.symptomId)
          .where('isAktif', isEqualTo: true)
          .where('umurMinBulan', isLessThanOrEqualTo: widget.usiaBulan)
          .orderBy('umurMinBulan')
          .orderBy('urutanRekomendasi')
          .get(const GetOptions(source: Source.server));
          debugPrint('=== CEK REKOMENDASI ===');
          debugPrint('symptomId: ${widget.symptomId}');
          debugPrint('usiaBulan: ${widget.usiaBulan}');
          debugPrint('jumlah data dari Firebase: ${snapshot.docs.length}');

      // Filter juga berdasarkan umurMaxBulan di client side
      final filtered = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final maxBulan = data['umurMaxBulan'] as int? ?? 9999;
            return widget.usiaBulan <= maxBulan;
          })
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      debugPrint('jumlah setelah filter umurMaxBulan: ${filtered.length}');

      // Fetch detail obat untuk setiap rekomendasi
      final result = <Map<String, dynamic>>[];
      for (final rek in filtered) {
        final obatId = rek['obatId'] as String?;
        if (obatId != null) {
          final obatDoc = await FirebaseFirestore.instance
              .collection('obat')
              .doc(obatId)
              .get();
          if (obatDoc.exists) {
            result.add({...rek, 'detailObat': obatDoc.data()});
          } else {
            result.add(rek);
          }
        }
      }

      setState(() {
        _rekomendasi = result;
        _loading = false;
      });
    } catch (e, s) {
      debugPrint("========== FIREBASE ERROR ==========");
      debugPrint(e.toString());
      debugPrint(s.toString());

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String get _labelUsia {
    final bulan = widget.usiaBulan;
    if (bulan < 12) return '$bulan bulan';
    final tahun = bulan ~/ 12;
    final sisaBulan = bulan % 12;
    if (sisaBulan == 0) return '$tahun tahun';
    return '$tahun tahun $sisaBulan bln';
  }

  @override
  Widget build(BuildContext context) {
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
          'Hasil Rekomendasi Obat',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.vx.textDark,
          ),
        ),
      ),
      body: PatternBackground(          // ← baris ini yang ganti
        child: SafeArea(
          child: Column(
            children: [
              // Info gejala + usia
              Container(
                width: double.infinity,
                color: context.vx.surface,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    _InfoChip(
                      icon: Icons.medical_services_outlined,
                      label: widget.symptomName,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.person_outline_rounded,
                      label: _labelUsia,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _error != null
                        ? _ErrorView(error: _error!, onRetry: _fetchRekomendasi)
                        : _rekomendasi.isEmpty
                            ? _EmptyView(symptom: widget.symptomName)
                            : _RekomendasiList(
                                rekomendasi: _rekomendasi,
                                usiaBulan: widget.usiaBulan,
                              ),
              ),

              // Disclaimer
              Container(
                width: double.infinity,
                color: context.vx.surface,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: context.vx.textLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rekomendasi ini bukan pengganti konsultasi medis. Jika keluhan berlanjut, segera periksakan ke tenaga kesehatan.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: context.vx.textLight,
                          height: 1.5,
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
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.vx.chipTeal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.vx.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.vx.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RekomendasiList extends StatelessWidget {
  final List<Map<String, dynamic>> rekomendasi;
  final int usiaBulan;

  const _RekomendasiList({required this.rekomendasi, required this.usiaBulan});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Berdasarkan gejala, kondisi, dan usia kamu.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: context.vx.textMedium,
          ),
        ),
        const SizedBox(height: 16),
        ...rekomendasi.map((rek) {
          final detail = rek['detailObat'] as Map<String, dynamic>?;
          final namaObat = detail?['namaObat'] ?? rek['obatId'] ?? '-';
          final golonganObat = detail?['golonganObat'] as String?;
          final dosisAturan = rek['dosisAturanPakai'] as String? ?? '-';

          // Subtitle: fungsi obat dari gejala
          String subtitle = '';
          if (rek['penyakitId'] == 'batuk') {
            subtitle = 'Untuk meredakan batuk';
          } else if (rek['penyakitId'] == 'demam') {
            subtitle = 'Untuk menurunkan demam';
          } else if (rek['penyakitId'] == 'flu') {
            subtitle = 'Untuk meredakan gejala flu';
          } else if (rek['penyakitId'] == 'diare') {
            subtitle = 'Untuk mengatasi diare';
          }

          return _ObatCard(
            namaObat: namaObat,
            golonganObat: golonganObat,
            subtitle: subtitle,
            dosis: dosisAturan,
            rekomendasiData: rek,
            usiaBulan: usiaBulan,
          );
        }),
      ],
    );
  }
}

class _ObatCard extends StatelessWidget {
  final String namaObat;
  final String? golonganObat;
  final String subtitle;
  final String dosis;
  final Map<String, dynamic> rekomendasiData;
  final int usiaBulan;

  const _ObatCard({
    required this.namaObat,
    required this.golonganObat,
    required this.subtitle,
    required this.dosis,
    required this.rekomendasiData,
    required this.usiaBulan,
  });

  // Mapping golonganObat -> asset gambar logo
  String? get _logoAsset {
    switch (golonganObat) {
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

  @override
  Widget build(BuildContext context) {
    final logoAsset = _logoAsset;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.vx.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.vx.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo obat sesuai golonganObat
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.vx.chipTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: logoAsset != null
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        logoAsset,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Icon(
                      Icons.medication_outlined,
                      color: context.vx.primary,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaObat,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.vx.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: context.vx.textMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 13, color: context.vx.textLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dosis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: context.vx.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailObatScreen(
                              rekomendasiData: rekomendasiData,
                              usiaBulan: usiaBulan,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.vx.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Lihat dosis & peringatan',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String symptom;
  const _EmptyView({required this.symptom});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: context.vx.textLight),
            const SizedBox(height: 16),
            Text(
              'Tidak ditemukan rekomendasi',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.vx.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada obat yang sesuai untuk $symptom pada usia ini. Silakan konsultasi ke dokter.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: context.vx.textMedium,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: context.vx.textLight),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.vx.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Periksa koneksi internet kamu dan coba lagi.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: context.vx.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.vx.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Coba Lagi',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}