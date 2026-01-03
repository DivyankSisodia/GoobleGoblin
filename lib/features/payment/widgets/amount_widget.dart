import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:gooble_goblin/core/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class AmountInput extends StatefulWidget {
  final TextEditingController controller;
  const AmountInput({super.key, required this.controller});

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  // Use the controller passed from parent
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;

    _controller.addListener(() {
      if (_controller.text.isEmpty) {
        _controller.text = "0.00";
        _controller.selection = const TextSelection.collapsed(offset: 4);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 64, 57, 68),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          /// Currency symbol
          Text(
            "\$",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNeon,
              fontFamily: GoogleFonts.sora().fontFamily,
            ),
          ),

          Gap(100),

          /// Amount input
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*\.?\d{0,2}'),
                ),
              ],
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.primaryNeon,
              cursorWidth: 3.0,
              cursorHeight: 34,
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              onChanged: (value) {
                if (!value.contains('.') && value.isNotEmpty) {
                  _controller.text = "$value.00";
                  _controller.selection =
                      TextSelection.collapsed(offset: value.length);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
