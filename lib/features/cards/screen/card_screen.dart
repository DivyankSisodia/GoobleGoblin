import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;

import '../../../core/colors.dart';
import '../../home/widget/custom_segmented_tab_bar.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  int selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.background,
        title: Text(
          'My Wallet',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage\nCards',
              style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
            ),
            Gap(12),
            Text(
              'Add or create new cards',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, fontFamily: GoogleFonts.montserrat().fontFamily),
            ),
            Gap(24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.surfaceLight.withOpacity(0.5), borderRadius: BorderRadius.circular(30)),
              child: CustomSegmentedTabBar(
                tabs: const ['Debit Card', 'Credit Card'],
                selectedIndex: selectedTabIndex,
                onChanged: (index) {
                  setState(() {
                    selectedTabIndex = index;
                  });
                },
                backgroundColor: AppColors.surfaceLight.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
