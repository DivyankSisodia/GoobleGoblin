import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

import 'core/DB/db_helper.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/notification_service.dart';
import 'features/main_screen.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.init();

  await DatabaseHelper.instance.database;
  await DatabaseHelper.instance.seedPredefinedCategories();

  runApp(const ProviderScope(child: GoobleGoblinApp()));
}

/// Main app widget with onboarding check
class GoobleGoblinApp extends ConsumerWidget {
  const GoobleGoblinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ToastificationWrapper(
      child: MaterialApp(
        title: 'GoobleGoblin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        locale: const Locale('en', 'IN'),
        supportedLocales: const [Locale('en', 'IN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _AppRouter(),
      ),
    );
  }
}

/// App router that checks onboarding status
class _AppRouter extends ConsumerWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingNeeded = ref.watch(isOnboardingNeededProvider);

    return onboardingNeeded.when(
      data: (needsOnboarding) {
        if (needsOnboarding) {
          return const OnboardingScreen();
        }
        return const MainScreen();
      },
      loading: () => const _SplashLoader(),
      error: (_, __) => const MainScreen(), // Fallback to main if error
    );
  }
}

/// Splash loading screen
class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.analyticsGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNeon.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            // Loading indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryNeon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
