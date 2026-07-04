import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'age_screen.dart';

class SymptomScreen extends StatefulWidget {
  const SymptomScreen({super.key});

  @override
  State<SymptomScreen> createState() => _SymptomScreenState();
}

class _SymptomScreenState extends State<SymptomScreen> {
  String? _selected;

  final List<Map<String, dynamic>> _symptoms = [
    {
      'id': 'flu',
      'name': 'Flu',
      'desc': 'Pilek, hidung\ntersumbat, bersin',
      'icon': Icons.sick_outlined,
    },
    {
      'id': 'batuk',
      'name': 'Batuk',
      'desc': 'Batuk kering\natau berdahak',
      'icon': Icons.air_outlined,
    },
    {
      'id': 'demam',
      'name': 'Demam',
      'desc': 'Suhu tubuh\nmeningkat, menggigil',
      'icon': Icons.thermostat_outlined,
    },
    {
      'id': 'diare',
      'name': 'Diare',
      'desc': 'Buang air besar\nlebih sering',
      'icon': Icons.water_drop_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Ini mengambil warna sesuai tema yang sedang aktif.
    // Light mode = warna AppColors
    // Dark mode = warna DarkColors
    final colors = context.vx;

    return Scaffold(
      // Sebelumnya: AppColors.background
      backgroundColor: colors.background,

      appBar: AppBar(
        // Sebelumnya: AppColors.white
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          // Tidak perlu diberi color karena AppBarTheme di app_theme.dart
          // sudah otomatis mengatur warna icon back.
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pilih Gejala',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            // Sebelumnya: AppColors.textDark
            color: colors.textDark,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Text(
                'Pilih gejala yang kamu alami.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  // Sebelumnya: AppColors.textMedium
                  color: colors.textMedium,
                ),
              ),

              const SizedBox(height: 24),

              // ─── Grid Gejala ──────────────────────────────────────
              Expanded(
                child: GridView.builder(
                  itemCount: _symptoms.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (ctx, i) {
                    final s = _symptoms[i];
                    final isSelected = _selected == s['id'];

                    return GestureDetector(
                      onTap: () => setState(() => _selected = s['id']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          // Card terpilih:
                          // light = teal muda
                          // dark = teal gelap transparan
                          color: isSelected
                              ? colors.primary.withValues(alpha: 0.10)
                              : colors.surface,

                          borderRadius: BorderRadius.circular(16),

                          border: Border.all(
                            color: isSelected
                                ? colors.primary
                                : colors.cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── Lingkaran icon ─────────────────────
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.primary.withValues(alpha: 0.15)
                                    : colors.chipTeal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                s['icon'] as IconData,
                                color: colors.primary,
                                size: 24,
                              ),
                            ),

                            const Spacer(),

                            Text(
                              s['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.textDark,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              s['desc'],
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: colors.textLight,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ─── Info bawah ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.chipTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Pilih satu gejala utama yang paling mengganggu saat ini.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: colors.primary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // ─── Lanjut Button ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AgeScreen(
                                symptomId: _selected!,
                                symptomName: _symptoms
                                    .firstWhere(
                                      (s) => s['id'] == _selected,
                                    )['name'] as String,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,

                    // Saat tombol belum bisa diklik.
                    disabledBackgroundColor: colors.inputBorder,
                    disabledForegroundColor: colors.textLight,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Lanjutkan',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,

                      // Ini sengaja TETAP Colors.white.
                      // Jangan ganti menjadi colors.white karena di dark mode
                      // colors.white isinya surface gelap.
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}