import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CardPreviewWidget extends StatelessWidget {
  final String bankName;
  final String balance;
  final bool isCredit;

  const CardPreviewWidget({
    super.key,
    required this.bankName,
    required this.balance,
    required this.isCredit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
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
    );
  }
}
