import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DatePickerPill extends StatefulWidget {
  const DatePickerPill({super.key});

  @override
  State<DatePickerPill> createState() => _DatePickerPillState();
}

class _DatePickerPillState extends State<DatePickerPill> {
  DateTime _selectedDate = DateTime.now();

  void _openDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Color(0xFF1A0E24),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      'Select Date',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.normal, decoration: TextDecoration.none),
                    ),
                  ),
                  CupertinoButton(
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                onDateTimeChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return GestureDetector(
      onTap: _openDatePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2A1038),
              Color(0xFF1A0E24),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// Text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Today' : 'Selected Date',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(_selectedDate),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                  ),
                ),
              ],
            ),

            /// Calendar Icon
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.calendar,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
