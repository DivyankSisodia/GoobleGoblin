import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final LocalAuthentication auth;
  bool _supportState = false;

  @override
  void initState() {
    super.initState();
    auth = LocalAuthentication();
    auth.isDeviceSupported().then(
      (value) => setState(() {
        _supportState = value;
      }),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(_supportState ? 'Biometric supported' : 'No biometric support'),
          SizedBox(height: 20),
          ElevatedButton(onPressed: getavailableBiometrics, child: const Text('Check Biometrics')),
          SizedBox(height: 20),
          ElevatedButton(onPressed: authenticate, child: const Text('Authenticate')),
        ],
      ),
    );
  }

  Future<void> authenticate() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to show account balance',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(signInTitle: 'Oops! Biometric authentication required!', cancelButton: 'No thanks'),
          IOSAuthMessages(cancelButton: 'No thanks'),
        ],
      );
      print("didAuthenticate: $didAuthenticate");
      // ···
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
}
