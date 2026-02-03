import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:gooble_goblin/core/colors.dart';
import 'package:gooble_goblin/features/main_screen.dart';
import 'package:gooble_goblin/utils/toast_notification.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget/3d_model_widget.dart';
import 'widget/animated_text_widget.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final LocalAuthentication auth;

  @override
  void initState() {
    super.initState();
    auth = LocalAuthentication();
    auth.isDeviceSupported().then(
      (value) => setState(() {
      }),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> authenticate() async {
    try {

      print("login state: ${await auth.isDeviceSupported()}");

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to show account balance',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(signInTitle: 'Oops! Biometric authentication required!', cancelButton: 'No thanks'),
          IOSAuthMessages(cancelButton: 'No thanks'),
        ],
      );
      print("didAuthenticate: $didAuthenticate");

      // store the authentication status in shared preferences if not present, if present then skip.
      bool isFirstTime = false;
      if (didAuthenticate) {
        final prefs = await SharedPreferences.getInstance();
        if(prefs.getBool('isAuthenticated') == null) {
          isFirstTime = true;
          await prefs.setBool('isAuthenticated', true);
        }
        print("shared prefs: ${prefs.getBool('isAuthenticated')}");
      }
      
      AppToasts.showSuccessToast(context);
      Navigator.push(context, MaterialPageRoute(builder: (context) => MainScreen(isFirstTime: isFirstTime)));
    } on LocalAuthException catch (e) {
      print("LocalAuthException: $e");
      if (e.code == LocalAuthExceptionCode.noBiometricHardware) {
        print("LocalAuthException: noBiometricHardware");
        // Add handling of no hardware here.
      } else if (e.code == LocalAuthExceptionCode.temporaryLockout || e.code == LocalAuthExceptionCode.biometricLockout) {
        print("LocalAuthException: temporaryLockout or biometricLockout");
        // ...
      } else {
        print("LocalAuthException: unknown");
        // ...
      }
    }
  }

  Future<void> getavailableBiometrics() async {
    final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();

    print("availableBiometrics list: $availableBiometrics");

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔥 Welcome (Full width)
                Gap(50),
                Text(
                  'Welcome Master\nDivyank',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 40, fontFamily: GoogleFonts.montserrat().fontFamily),
                ),

                const SizedBox(height: 32),

                /// 🔥 Text + 3D Model Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🧠 LEFT — Alfred Texts
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          Text(
                            "I'm Alfred to\nserve you!!",
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontFamily: GoogleFonts.montserrat().fontFamily),
                          ),
                          SizedBox(height: 28),
                          HindiScrambleText(
                            text: 'नमस्ते, मैं अल्फ्रेड\nआपका बटलर हूँ    ',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontFamily: GoogleFonts.montserrat().fontFamily),
                          ),

                          const SizedBox(height: 28),

                          SlidingText(
                            text: 'Hallo, ich bin\nAlfred Ihr Butler',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontFamily: GoogleFonts.montserrat().fontFamily),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    /// 🎮 RIGHT — 3D Model
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30.0),
                        child: Align(alignment: Alignment.topCenter, child: Rotating3DModel()),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 100),
                // ElevatedButton(onPressed: (){}, child: child)
                Container(
                  height: 60,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ElevatedButton(
                    onPressed: authenticate,
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(AppColors.primaryNeonDark.withOpacity(0.7)),
                      foregroundColor: WidgetStatePropertyAll(AppColors.textPrimary),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      // padding: WidgetStatePropertyAll(const EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
                    ),
                    child: Text(
                      'Authenticate',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
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
