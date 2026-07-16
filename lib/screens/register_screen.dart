import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/shared_widgets.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _auth = AuthService();

  bool _agreeTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      showError(context, 'Harap setujui kebijakan privasi terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.register(
        fullName: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/doodle.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Tombol kembali
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: AppColors.textDark),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Kartu form
              Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── Header ──────────────────────────
                            Text(
                              'Buat Akun',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Daftar untuk mulai menggunakan Valenx.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textMedium,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ─── Form Fields ─────────────────────
                            ValenxInput(
                              hint: 'Nama Lengkap',
                              controller: _nameCtrl,
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Nama tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            ValenxInput(
                              hint: 'E-mail',
                              controller: _emailCtrl,
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!v.contains('@') || !v.contains('.')) {
                                  return 'Format email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            ValenxInput(
                              hint: 'Password',
                              controller: _passCtrl,
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }
                                if (v.length < 6) {
                                  return 'Password minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            ValenxInput(
                              hint: 'Konfirmasi Password',
                              controller: _confirmCtrl,
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              validator: (v) {
                                if (v != _passCtrl.text) {
                                  return 'Password tidak cocok';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // ─── Terms & Conditions ──────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _agreeTerms,
                                    onChanged: (v) => setState(
                                        () => _agreeTerms = v ?? false),
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    side: const BorderSide(
                                        color: AppColors.inputBorder,
                                        width: 1.5),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'Saya setuju dengan ',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.textMedium,
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              'Kebijakan Privasi dan Ketentuan Layanan',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ─── Daftar Button ───────────────────
                            PrimaryButton(
                              text: 'Daftar',
                              onPressed: _register,
                              isLoading: _isLoading,
                            ),

                            const SizedBox(height: 20),

                            // ─── Link ke Login ───────────────────
                            Center(
                              child: Text.rich(
                                TextSpan(
                                  text: 'Sudah punya akun? ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textMedium,
                                  ),
                                  children: [
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () => Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const LoginScreen()),
                                        ),
                                        child: Text(
                                          'Masuk',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}