import 'package:flutter/material.dart';
import 'package:gooble_goblin/core/colors.dart';

class RecurringPaymentTile extends StatefulWidget {
  const RecurringPaymentTile({super.key});

  @override
  State<RecurringPaymentTile> createState() => _RecurringPaymentTileState();
}

class _RecurringPaymentTileState extends State<RecurringPaymentTile> {
  bool isSelected = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [
              Color(0xFF2A1038),
              Color(0xFF1A0E24),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // 1. Circular Icon Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF4A1D4A), // Slightly lighter purple for the circle
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history, // Closest material icon to the "recurring" symbol
              color: AppColors.textPrimary, // Bright magenta icon color
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          
          // 2. Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Recurring',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set up repeat payments',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // 3. Custom Switch
          Switch(
            value: isSelected,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFFE040FB),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.black26,
            onChanged: (bool value) {
              setState(() {
                isSelected = value;
              });
            },
          ),
        ],
      ),
    );
  }
}