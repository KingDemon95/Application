import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'age_screen.dart';
import '../widgets/pattern_background.dart';

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
      'icon': '🤧',
    },
    {
      'id': 'batuk',
      'name': 'Batuk',
      'desc': 'Batuk kering\natau berdahak',
      'icon': '😮‍💨',
    },
    {
      'id': 'demam',
      'name': 'Demam',
      'desc': 'Suhu tubuh\nmeningkat, menggigil',
      'icon': '🤒',
    },
    {
      'id': 'diare',
      'name': 'Diare',
      'desc': 'Buang air besar\nlebih sering',
      'icon': '🤢',
    },
  ];

  Widget _buildCard(Map<String, dynamic> s, ValenxColors colors) {
    final isSelected = _selected == s['id'];

    return GestureDetector(
      onTap: () => setState(() => _selected = s['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        decoration: BoxDecoration(
          // Card terpilih:
          // light = teal muda
          // dark = teal gelap transparan
          color: isSelected
              ? colors.primary.withValues(alpha: 0.10)
              : colors.surface,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: isSelected ? colors.primary : colors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ─── Lingkaran icon (emoji) ─────────────────────
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.15)
                    : colors.chipTeal,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                s['icon'] as String,
                style: const TextStyle(fontSize: 20),
              ),
            ),

            const SizedBox(height: 12),

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
  }

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

      body: PatternBackground(          // ← baris ini yang ganti
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ─── Maskot dokter + speech bubble ─────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Lebar dilebarin supaya height 275 beneran terpakai penuh,
                    // sebelumnya width 150 terlalu sempit jadi gambar
                    // disusutkan lagi oleh BoxFit.contain (kena batas lebar
                    // duluan sebelum tingginya sempat mencapai 275).
                    SizedBox(
                      width: 200,
                      height: 275,
                      child: Image.asset(
                        'assets/images/doctor1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SpeechBubble(colors: colors),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ─── Grid Gejala (meregang ngisi sisa ruang) ───────────
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _buildCard(_symptoms[0], colors)),
                            const SizedBox(width: 14),
                            Expanded(child: _buildCard(_symptoms[1], colors)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _buildCard(_symptoms[2], colors)),
                            const SizedBox(width: 14),
                            Expanded(child: _buildCard(_symptoms[3], colors)),
                          ],
                        ),
                      ),
                    ],
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
      ),
    );
  }
}

// ─── Speech bubble instruksi ──────────────────────────────────────────────
class _SpeechBubble extends StatelessWidget {
  final ValenxColors colors;
  const _SpeechBubble({required this.colors});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTailPainter(color: colors.chipTeal),
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.chipTeal,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pilih satu gejala',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'yang paling mengganggu saat ini, ya!',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: colors.textMedium,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Segitiga kecil "ekor" bubble yang mengarah ke kiri (ke arah maskot)
class _BubbleTailPainter extends CustomPainter {
  final Color color;
  const _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(10, size.height / 2 - 8)
      ..lineTo(0, size.height / 2)
      ..lineTo(10, size.height / 2 + 8)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.color != color;
}