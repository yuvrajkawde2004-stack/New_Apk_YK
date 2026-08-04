import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/cloudflare_api_service.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _agreeTerms = true;
  bool _isSignUpMode = false;
  bool _isLoading = false;
  int _otpTimer = 0;
  Timer? _timer;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleLoginOrSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both Email/Mobile and Password/OTP'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to terms and conditions to proceed'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await CloudflareApiService.verifyOtp(target: email, code: password);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSignUpMode ? 'Account created successfully!' : 'Login Successful! Welcome back.'),
          backgroundColor: AppColors.emeraldGreen,
        ),
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login failed. Please check your OTP or Password.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final googleAccounts = [
      'user.retailflow@gmail.com',
      'shopowner.pos@gmail.com',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final emailInputCtrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.g_mobiledata_rounded, color: Color(0xFFEA4335), size: 36),
                  const SizedBox(width: 8),
                  Text('Choose Google Account', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text('Select an account to login & sync data with Cloud database:', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 16),

              ...googleAccounts.map((acc) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEA4335).withValues(alpha: 0.1),
                  child: Text(acc[0].toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFEA4335))),
                ),
                title: Text(acc, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Google Account', style: GoogleFonts.outfit(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                onTap: () async {
                  Navigator.pop(ctx);
                  _emailController.text = acc;
                  await _sendOtp();
                },
              )),
              
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.add, color: Colors.white),
                ),
                title: Text('Use another Google Email', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text('Enter Gmail Address', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      content: TextField(
                        controller: emailInputCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'example@gmail.com', border: OutlineInputBorder()),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () async {
                            final email = emailInputCtrl.text.trim();
                            if (email.isNotEmpty) {
                              Navigator.pop(dCtx);
                              Navigator.pop(ctx);
                              _emailController.text = email;
                              await _sendOtp();
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                          child: const Text('Send Gmail OTP', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendOtp() async {
    final target = _emailController.text.trim();
    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Email or Mobile Number first'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final type = target.contains('@') ? 'gmail' : 'mobile';
    final result = await CloudflareApiService.sendOtp(target: target, type: type);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        _otpTimer = 30;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_otpTimer > 0) {
            _otpTimer--;
          } else {
            timer.cancel();
          }
        });
      });

      // Auto-fill OTP for easier testing since SMS might not arrive
      if (result['debug_otp'] != null) {
        _passwordController.text = result['debug_otp'].toString();
      }

      final debugOtp = result['debug_otp'] != null ? '\n(Auto-filled OTP: ${result['debug_otp']})' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result['message']}$debugOtp'),
          backgroundColor: AppColors.emeraldGreen,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to send OTP'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Stack(
            children: [
              // ────────────────── TOP GREEN HERO SECTION ──────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: size.height * 0.42,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF00E676),
                        Color(0xFF10B981),
                        Color(0xFF059669),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Geometric translucent stripe overlays (Matching design image)
                      Positioned(
                        top: -40,
                        right: -30,
                        child: Transform.rotate(
                          angle: -0.35,
                          child: Container(
                            width: 220,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 80,
                        left: -50,
                        child: Transform.rotate(
                          angle: -0.35,
                          child: Container(
                            width: 260,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),

                      // Central Brand Emblem & App Title
                      SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),
                              // RetailFlow Logo Image
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              )
                                  .animate()
                                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                                  .fadeIn(duration: 500.ms),

                              const SizedBox(height: 14),

                              Text(
                                'RetailFlow',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2, end: 0),

                              const SizedBox(height: 4),

                              Text(
                                'Premium Retail Management',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ).animate().fadeIn(delay: 300.ms),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ────────────────── BOTTOM WHITE FORM CARD ──────────────────
              Positioned(
                top: size.height * 0.36,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 24,
                        offset: Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "hello!" Heading (as in design image)
                        Center(
                          child: Text(
                            'hello!',
                            style: GoogleFonts.outfit(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF10B981),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 20),

                        // Form Inputs
                        if (_isSignUpMode) ...[
                          _buildInputField(
                            controller: _usernameController,
                            hint: 'Username',
                            icon: Icons.person_outline_rounded,
                            delayMs: 200,
                          ),
                          const SizedBox(height: 14),
                        ],

                        _buildInputField(
                          controller: _emailController,
                          hint: 'Email or Mobile Number',
                          icon: Icons.email_outlined,
                          type: TextInputType.emailAddress,
                          delayMs: 250,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: (_isLoading || _otpTimer > 0) ? null : _sendOtp,
                            child: Text(
                              _otpTimer > 0 ? 'Wait ${_otpTimer}s' : 'Send OTP',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),

                        _buildInputField(
                          controller: _passwordController,
                          hint: 'OTP',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          isPasswordVisible: _isPasswordVisible,
                          onTogglePassword: () {
                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                          },
                          delayMs: 300,
                        ),
                        
                        // Countdown Timer UI
                        if (_otpTimer > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, right: 10),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'OTP is valid for ${_otpTimer}s',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ).animate().fadeIn(),
                          ),
                          
                        const SizedBox(height: 14),

                        // Checkbox row
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreeTerms,
                                activeColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (v) => setState(() => _agreeTerms = v ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'I agree to the terms and conditions',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 350.ms),

                        const SizedBox(height: 22),

                        // Primary Action Button ("Sign Up" / "Log In")
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF00E676),
                                Color(0xFF10B981),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _handleLoginOrSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    _isSignUpMode ? 'Sign Up' : 'Log In',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),

                        const SizedBox(height: 18),

                        // Divider (- or -)
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'or',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                          ],
                        ).animate().fadeIn(delay: 450.ms),

                        const SizedBox(height: 18),

                        // Social Media Buttons (Red, Yellow, Blue rounded buttons)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 250,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: _handleGoogleSignIn,
                                borderRadius: BorderRadius.circular(30),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.g_mobiledata_rounded, color: Color(0xFFEA4335), size: 36),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Continue with Google',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().slideY(delay: 500.ms, begin: 0.3, end: 0).fadeIn(),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Center(
                          child: Text(
                            'Log in with your social media account',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ).animate().fadeIn(delay: 550.ms),

                        const SizedBox(height: 12),

                        // Mode Toggle Footer Link
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _isSignUpMode = !_isSignUpMode);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _isSignUpMode
                                    ? 'I already have an account'
                                    : 'Don\'t have an account? Sign Up',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOutCubic).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? type,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    required int delayMs,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: isPassword && !isPasswordVisible,
        style: GoogleFonts.outfit(
          fontSize: 15,
          color: AppColors.textPrimaryLight,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: AppColors.textSecondaryLight.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 10),
            child: Icon(icon, color: AppColors.textSecondaryLight, size: 20),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.textSecondaryLight,
                    size: 20,
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.8),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delayMs.ms).slideX(begin: 0.08, end: 0);
  }

  Widget _socialButton({
    required Color color,
    required IconData icon,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}
