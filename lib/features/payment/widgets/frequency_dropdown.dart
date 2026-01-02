import 'package:flutter/material.dart';

class FrequencyDropdown extends StatefulWidget {
  const FrequencyDropdown({super.key});

  @override
  State<FrequencyDropdown> createState() => _FrequencyDropdownState();
}

class _FrequencyDropdownState extends State<FrequencyDropdown> {
  String selectedFrequency = 'Monthly';
  final List<String> options = ['Daily', 'Weekly', 'Monthly'];

  void _showPicker() {
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
                setState(() => selectedFrequency = option);
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
      onTap: _showPicker,
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
                color: Color(0xFFE040FB), // Magenta text
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFFE040FB), // Magenta arrow
            ),
          ],
        ),
      ),
    );
  }
}