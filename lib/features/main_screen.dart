import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'analytics/screens/analytics_screen.dart';
import 'cards/screen/card_screen.dart';
import 'home/screen/home_screen.dart';
import 'payment/screen/new_payment_screen.dart';
import 'payment/screen/wallet_history_screen.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  final bool isFirstTime;
  const MainScreen({super.key, this.isFirstTime = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    final List<Widget> screens = [
      HomeScreen(isFirstTime: isFirstTime),
      CardsScreen(),
      const NewPaymentScreen(),
      const WalletHistoryScreen(),
      const AnalyticsScreen(), 
    ];

    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: selectedIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.home_rounded, size: 30, color: Colors.black),
          Icon(Icons.credit_card_rounded, size: 30, color: Colors.black),
          Icon(Icons.add_rounded, size: 30, color: Colors.black),
          Icon(Icons.history_rounded, size: 30, color: Colors.black),
          Icon(
            Icons.insights_rounded,
            size: 30,
            color: Colors.black,
          ), // Changed to insights icon
        ],
        color: AppColors.primaryNeon,
        buttonBackgroundColor: AppColors.primaryNeon,
        backgroundColor: AppColors.background,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
