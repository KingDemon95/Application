import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../main.dart'; // untuk themeProvider
import 'login_screen.dart';
import 'symptom_screen.dart';
import 'pengingat_list_screen.dart'; // TODO: pastikan file ini ada, lihat catatan di bawah

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    // Cek notifikasi pending (app dibuka dari terminated via klik notif)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().handlePendingNavigation();
    });
  }

  String get _firstName {
    final name = FirebaseAuth.instance.currentUser?.displayName ?? 'User';
    return name.split(' ').first;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi!';
    if (hour < 15) return 'Selamat siang!';
    if (hour < 18) return 'Selamat sore!';
    return 'Selamat malam!';
  }

  String get _greetingEmoji {
    final hour = DateTime.now().hour;
    if (hour < 11) return '🌤️';
    if (hour < 15) return '☀️';
    if (hour < 18) return '🌅';
    return '🌙';
  }

  Future<void> _logout() async {
    final confirm = await _showConfirmDialog(
      title: 'Keluar Akun',
      content: 'Yakin ingin keluar dari akun?',
      confirmText: 'Keluar',
    );
    if (confirm == true) {
      await _auth.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  Future<void> _exitApp() async {
    final confirm = await _showConfirmDialog(
      title: 'Keluar Aplikasi',
      content: 'Yakin ingin menutup aplikasi?',
      confirmText: 'Tutup',
    );
    if (confirm == true) {
      SystemNavigator.pop();
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
  }) {
    final vx = Theme.of(context).extension<ValenxColors>() ?? ValenxColors.light;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: vx.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: vx.textDark)),
        content: Text(content,
            style: GoogleFonts.poppins(fontSize: 14, color: vx.textMedium)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: vx.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: vx.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText,
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vx = context.vx;

    return Scaffold(
      backgroundColor: vx.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ─── Top Bar ─────────────────────────
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: vx.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _HeaderIconButton(
                      icon: Icons.notifications_active_rounded,
                      tooltip: 'Pengingat Obat',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PengingatListScreen()),
                        );
                      },
                      iconColor: vx.primary,
                    ),
                    Row(
                      children: [
                        _HeaderIconButton(
                          icon: context.isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          tooltip:
                              context.isDark ? 'Mode Terang' : 'Mode Gelap',
                          onTap: () => themeProvider.toggle(),
                          iconColor: vx.primary,
                        ),
                        const SizedBox(width: 10),
                        _HeaderIconButton(
                          icon: Icons.logout_rounded,
                          tooltip: 'Logout',
                          onTap: _logout,
                          iconColor: vx.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Greeting ────────────────────────────────────────
              Text(
                'Halo, $_firstName $_greetingEmoji',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: vx.textMedium,
                ),
              ),
              Text(
                _greeting,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: vx.textDark,
                ),
              ),
              Text(
                'Kesehatanmu, prioritas kami.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: vx.textLight,
                ),
              ),

              // ─── Ilustrasi Dokter ────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    // Karakter dokter
                    Center(
                      child: Image.asset(
                        'assets/images/doctor.png',
                        height: 400,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Card Cek Gejala ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: vx.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bagaimana perasaanmu\nhari ini?',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mulai cek gejala untuk\nmendapatkan rekomendasi.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SymptomScreen()),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: context.isDark
                                    ? DarkColors.surface
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Mulai Cek Gejala',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: vx.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.search_rounded,
                          color: Colors.white, size: 26),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─── Tombol Keluar Aplikasi ──────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _exitApp,
                  icon: Icon(Icons.exit_to_app_rounded,
                      size: 20, color: vx.primary),
                  label: Text(
                    'Keluar Aplikasi',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: vx.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: vx.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

// ─── Header Icon Button (tombol bulat putih di top bar) ────────────────────
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color iconColor;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}