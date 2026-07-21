import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'hasil_rekomendasi_screen.dart';
import '../widgets/pattern_background.dart';

class AgeScreen extends StatefulWidget {
  final String symptomId;
  final String symptomName;

  const AgeScreen({
    super.key,
    required this.symptomId,
    required this.symptomName,
  });

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  double _usiaBulan = 26;

  String get _labelUsia {
    final bulan = _usiaBulan.round();
    if (bulan < 12) return '$bulan bulan';
    final tahun = bulan ~/ 12;
    final sisaBulan = bulan % 12;
    if (sisaBulan == 0) return '$tahun tahun';
    return '$tahun tahun $sisaBulan bulan';
  }

  String get _kategoriUsia {
    final bulan = _usiaBulan.round();
    if (bulan < 24) return 'Bayi';
    if (bulan < 60) return 'Balita';
    if (bulan < 144) return 'Anak-anak';
    if (bulan < 216) return 'Remaja';
    if (bulan < 720) return 'Dewasa';
    return 'Lansia';
  }

  IconData get _ikonUsia {
    final bulan = _usiaBulan.round();
    if (bulan < 24) return Icons.child_care_rounded;
    if (bulan < 60) return Icons.child_friendly_rounded;
    if (bulan < 144) return Icons.face_rounded;
    if (bulan < 216) return Icons.person_outline_rounded;
    if (bulan < 720) return Icons.person_rounded;
    return Icons.elderly_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.vx.background,
      appBar: AppBar(
        backgroundColor: context.vx.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Usia Pengguna',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: PatternBackground(          // ← baris ini yang ganti
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // ─── Konten yang di-center di sisa ruang ─────────────
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Berapa usia kamu?',
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: context.vx.textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pilih usia dalam bulan untuk\nhasil yang lebih tepat.',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: context.vx.textMedium,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),

                          // Ilustrasi ikon usia
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: context.vx.chipTeal,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _ikonUsia,
                              size: 150,
                              color: context.vx.primary,
                            ),
                          ),

                          const SizedBox(height: 8),
                          Text(
                            _kategoriUsia,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: context.vx.primary,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Angka usia besar
                          Text(
                            _labelUsia,
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: context.vx.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_usiaBulan.round()} bulan',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: context.vx.textMedium,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Slider
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: context.vx.primary,
                              inactiveTrackColor: context.vx.inputBorder,
                              thumbColor: context.vx.primary,
                              overlayColor:
                                  context.vx.primary.withValues(alpha: 0.12),
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 12),
                              trackHeight: 6,
                            ),
                            child: Slider(
                              value: _usiaBulan,
                              min: 0,
                              max: 1200,
                              divisions: 1200,
                              onChanged: (val) =>
                                  setState(() => _usiaBulan = val),
                            ),
                          ),

                          // Label min max slider
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('0',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: context.vx.textLight)),
                                Text('300',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: context.vx.textLight)),
                                Text('600',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: context.vx.textLight)),
                                Text('900',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: context.vx.textLight)),
                                Text('1200',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: context.vx.textLight)),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('bayi',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: context.vx.textLight)),
                                const Spacer(),
                                Text('100 thn',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: context.vx.textLight)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── Tombol lanjutkan (pin di bawah) ──────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HasilRekomendasiScreen(
                              symptomId: widget.symptomId,
                              symptomName: widget.symptomName,
                              usiaBulan: _usiaBulan.round(),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.vx.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Lanjutkan',
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
        ),
      ),
    );
  }
}