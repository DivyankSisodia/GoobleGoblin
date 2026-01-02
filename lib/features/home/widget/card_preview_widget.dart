import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gooble_goblin/core/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class CardPreviewWidget extends ConsumerWidget {
  final String bankName;
  final String balance;
  final bool isCredit;
  final bool isSelected;
  final VoidCallback? onTap;

  const CardPreviewWidget({
    super.key,
    required this.bankName,
    required this.balance,
    required this.isCredit,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 340,
        height: 200,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCredit 
              ? [const Color(0xFF2D1B4E), const Color(0xFF1A102E)] 
              : [const Color(0xFF1E3A34), const Color(0xFF10211D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected 
              ? AppColors.primaryNeon 
              : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? AppColors.primaryNeon.withOpacity(0.3)
                : Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bankName.isEmpty ? 'BANK NAME' : bankName.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                  ),
                ),
                Icon(
                  Icons.contactless_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 28,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Balance',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      balance.isEmpty ? '₹ 0.00' : '₹ $balance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: GoogleFonts.montserrat().fontFamily,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '**** **** **** 1234',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    letterSpacing: 2,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                  ),
                ),
                Text(
                  isCredit ? 'CREDIT' : 'DEBIT',
                  style: TextStyle(
                    color: isCredit ? const Color(0xFFB0FF38) : Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
