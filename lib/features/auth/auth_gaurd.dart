import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:gooble_goblin/core/theme/app_theme.dart';
import 'package:gooble_goblin/features/main_screen.dart';
import 'package:gooble_goblin/utils/toast_notification.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'widget/3d_model_widget.dart';
import 'widget/animated_text_widget.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> authenticate() async {
    final authNotifier = ref.read(authProvider.notifier);

    try {
      final didAuthenticate = await authNotifier.authenticate();

      if (didAuthenticate && mounted) {
        AppToasts.showSuccessToast(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      debugPrint('Authentication error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication failed. Please try again.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(50),
              Text(
                'Welcome Master\nDivyank',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 40,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                ),
              ),
              const SizedBox(height: 32),

              /// Text + 3D Model Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// LEFT - Alfred Texts
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          "I'm Alfred to\nserve you!!",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontFamily: GoogleFonts.montserrat().fontFamily,
                          ),
                        ),
                        const SizedBox(height: 28),
                        HindiScrambleText(
                          text: 'नमस्ते, मैं अल्फ्रेड\nआपका बटलर हूँ    ',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontFamily: GoogleFonts.montserrat().fontFamily,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SlidingText(
                          text: 'Hallo, ich bin\nAlfred Ihr Butler',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontFamily: GoogleFonts.montserrat().fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  /// RIGHT - 3D Model
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30.0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Rotating3DModel(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100),

              /// Authenticate Button
              Container(
                height: 60,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : authenticate,
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      AppColors.primaryNeonDark.withOpacity(0.7),
                    ),
                    foregroundColor: WidgetStatePropertyAll(
                      AppColors.textPrimary,
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Authenticate',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: GoogleFonts.montserrat().fontFamily,
                          ),
                        ),
                ),
              ),

              /// Skip for now text (for devices without biometrics)
              if (!authState.canCheckBiometrics) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
