import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';

class TotalBalanceWidget extends StatelessWidget {
  const TotalBalanceWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 16.0, top: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(CupertinoIcons.eye_slash, color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24.0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              '₹ 66,660',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
            ),
          ),
        ),
        Gap(16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryNeonDark),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.transparent
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: AppColors.primaryNeonDark, size: 14),
                    Gap(8),
                    Text(
                      '+450\$ (3.2%)',
                      style: TextStyle(
                        color: AppColors.primaryNeonDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: GoogleFonts.montserrat().fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              Gap(16),
              Text(
                'vs Last Month',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
            ],
          ),
        ),
        Gap(16),
      ],
    );
  }
}
