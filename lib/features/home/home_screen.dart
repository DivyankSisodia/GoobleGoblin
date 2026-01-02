import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:gooble_goblin/core/colors.dart';
import 'package:gooble_goblin/features/experiment/exp1.dart' show NotificationService;
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

import 'widget/circular_progress_widget.dart';
import 'widget/total_balance_widget.dart';

class HomeScreen extends StatefulWidget {
  final bool isFirstTime;
  const HomeScreen({super.key, this.isFirstTime = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.isFirstTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _showWelcomeBottomSheet(context);
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: Center(
          child: Container(
            height: 42,
            width: 42,
            decoration: const BoxDecoration(color: AppColors.primaryNeon, shape: BoxShape.circle),
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 24,
              icon: const Icon(CupertinoIcons.chart_bar, color: Colors.black),
              onPressed: () {},
            ),
          ),
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gooble Goblin",
              style: TextStyle(color: AppColors.primaryNeon, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
            ),
            Text(
              "Hello Divyank",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
            ),
          ],
        ),
        actions: [
          Container(
            height: 42,
            width: 42,
            decoration: const BoxDecoration(color: AppColors.primaryNeon, shape: BoxShape.circle),
            child: IconButton(
              onPressed: () {},
              icon: Icon(CupertinoIcons.person, color: Colors.black, size: 24),
            ),
          ),
          Gap(20),
        ],
      ),
      // Matching AppColors.background
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Gap(30),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.surfaceLight.withOpacity(0.8), borderRadius: BorderRadius.circular(16)),
            child: TotalBalanceWidget(),
          ),
          Gap(20),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.surfaceLight.withOpacity(0.8), borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Budget',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400, fontFamily: GoogleFonts.montserrat().fontFamily),
                        ),
                        Gap(16),
                        Text(
                          '₹ 66,660',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
                        ),
                        Text(
                          '₹ 66,660',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
                        ),
                      ],
                    ),
                    Gap(20),
                    Container(
                      padding: const EdgeInsets.all(8),
                      // decoration: BoxDecoration(color: AppColors.primaryNeon, borderRadius: BorderRadius.circular(16)),
                      child: CircularPercentWidget(
                        currentValue: 45645.4,
                        totalValue: 66666.66,
                        progressColor: Colors.green,
                        size: 70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showWelcomeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1B29),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 32),
              const Icon(Icons.celebration_rounded, size: 64, color: Color(0xFFB0FF38)),
              const SizedBox(height: 24),
              const Text(
                'Welcome, Master!',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'We are glad to have you back. Explore your new dashboard and manage your tasks efficiently.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB0FF38),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Get Started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
