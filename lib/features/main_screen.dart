import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gooble_goblin/core/colors.dart';
import 'package:gooble_goblin/features/home/home_screen.dart';
import 'package:gooble_goblin/features/payment/screen/new_payment_screen.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  final bool isFirstTime;
  const MainScreen({super.key, this.isFirstTime = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    final List<Widget> screens = [
      HomeScreen(isFirstTime: isFirstTime),
      const PlaceholderScreen(title: 'Cards'),
      const NewPaymentScreen(),
      const PlaceholderScreen(title: 'History'),
      const PlaceholderScreen(title: 'Settings'),
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
          Icon(Icons.settings_rounded, size: 30, color: Colors.black),
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
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
