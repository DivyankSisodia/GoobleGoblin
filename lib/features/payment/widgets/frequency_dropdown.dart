import 'package:flutter/material.dart';
import 'package:gooble_goblin/core/colors.dart';

class FrequencyDropdown extends StatelessWidget {
  final String selectedFrequency;
  final ValueChanged<String> onChanged;

  const FrequencyDropdown({
    super.key,
    required this.selectedFrequency,
    required this.onChanged,
  });

  final List<String> options = const ['Daily', 'Weekly', 'Monthly'];

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A121A), // Match dark background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return ListTile(
              title: Text(
                option,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              onTap: () {
                onChanged(option);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent, // Background of the pill
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white12, // Subtle border like in image
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedFrequency,
              style: const TextStyle(
                color: AppColors.primaryNeonDark, // Magenta text
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.primaryNeonDark, // Magenta arrow
            ),
          ],
        ),
      ),
    );
  }
}