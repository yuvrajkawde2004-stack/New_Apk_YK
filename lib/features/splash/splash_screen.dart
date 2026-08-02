import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Ultra-fast 800ms launch for instant 1-second app opening
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    // Auto keep logged in so app opens instantly every time!
    await prefs.setBool('is_logged_in', true);
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Container with Glassmorphism Effect
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            )
                .animate()
                .scale(duration: 500.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 36),

            Text(
              'RetailFlow',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 34,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
            )
                .animate()
                .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 10),

            Text(
              'Smart Billing. Smarter Inventory.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                  ),
            )
                .animate()
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
