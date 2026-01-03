import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:gooble_goblin/core/app_images.dart';
import 'package:gooble_goblin/core/colors.dart';
import 'package:google_fonts/google_fonts.dart';

import 'custom_segmented_tab_bar.dart';

class TransactionItem {
  final String title;
  final String date;
  final String amount;
  final String icon;
  final Color iconColor;

  TransactionItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });
}

class CustomTabWidget extends StatefulWidget {
  const CustomTabWidget({super.key});

  @override
  State<CustomTabWidget> createState() => _CustomTabWidgetState();
}

class _CustomTabWidgetState extends State<CustomTabWidget> {
  final List<String> tabs = ['Transactions', 'Cards', 'Categories'];
  int selectedIndex = 0;

  final Map<int, List<TransactionItem>> tabContent = {
    0: [
      TransactionItem(title: 'Netflix', date: '02 Jan 2024', amount: '- ₹ 1,499', icon: AppImages.netflix, iconColor: const Color(0xFFE50914)),
      TransactionItem(title: 'Zomato', date: '01 Jan 2024', amount: '- ₹ 450', icon: AppImages.zomato, iconColor: const Color(0xFFCB202D)),
      TransactionItem(title: 'Swiggy', date: '31 Dec 2023', amount: '- ₹ 320', icon: AppImages.swiggy, iconColor: const Color(0xFFFF5200)),
      TransactionItem(title: 'Youtube', date: '30 Dec 2023', amount: '- ₹ 129', icon: AppImages.youtube, iconColor: const Color(0xFFFF0000)),
    ],
    1: [
      TransactionItem(title: 'HDFC Bank Tap', date: 'Primary Card', amount: '₹ 45,000', icon: AppImages.mobile, iconColor: AppColors.primaryNeon),
      TransactionItem(title: 'ICICI Amazon Pay', date: 'Shopping Card', amount: '₹ 12,500', icon: AppImages.bagShopping, iconColor: Colors.orange),
    ],
    2: [
      TransactionItem(title: 'Food & Drinks', date: '12 Transactions', amount: '₹ 8,420', icon: AppImages.zomato, iconColor: AppColors.primaryNeon),
      TransactionItem(title: 'Entertainment', date: '5 Transactions', amount: '₹ 2,100', icon: AppImages.youtube, iconColor: Colors.purpleAccent),
      TransactionItem(title: 'Shopping', date: '8 Transactions', amount: '₹ 15,300', icon: AppImages.bagShopping, iconColor: Colors.blueAccent),
      TransactionItem(title: 'Travel', date: '4 Transactions', amount: '₹ 4,500', icon: AppImages.bike, iconColor: Colors.greenAccent),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomSegmentedTabBar(
          tabs: tabs,
          selectedIndex: selectedIndex,
          onChanged: (index) {
            setState(() => selectedIndex = index);
          },
        ),
        const Gap(24),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: tabContent[selectedIndex]?.length ?? 0,
          separatorBuilder: (context, index) => const Gap(12),
          itemBuilder: (context, index) {
            final item = tabContent[selectedIndex]![index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      item.icon,
                      color: item.iconColor,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: GoogleFonts.montserrat().fontFamily,
                          ),
                        ),
                        Text(
                          item.date,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontFamily: GoogleFonts.montserrat().fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.amount,
                    style: TextStyle(
                      color: item.amount.startsWith('-') ? Colors.white : AppColors.primaryNeon,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: GoogleFonts.montserrat().fontFamily,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const Gap(20),
      ],
    );
  }
}
