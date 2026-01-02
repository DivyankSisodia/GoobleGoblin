import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:gooble_goblin/core/app_images.dart';
import 'package:gooble_goblin/core/colors.dart';
import 'package:gooble_goblin/features/home/provider/cards_provider.dart';
import 'package:gooble_goblin/features/payment/widgets/amount_widget.dart';
import 'package:gooble_goblin/features/payment/widgets/custom_chip_widget.dart';
import 'package:gooble_goblin/features/payment/widgets/custom_date_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../cards/widget/card_preview_widget.dart';
import '../../experiment/exp1.dart';
import '../widgets/frequency_dropdown.dart';
import '../widgets/reoccuring_payment_widget.dart';
import '../../category/provider/category_provider.dart';

class NewPaymentScreen extends ConsumerStatefulWidget {
  const NewPaymentScreen({super.key});

  @override
  ConsumerState<NewPaymentScreen> createState() => _NewPaymentScreenState();
}

class _NewPaymentScreenState extends ConsumerState<NewPaymentScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isReminderEnabled = false;
  DateTime _reminderDateTime = DateTime.now().add(const Duration(days: 1));

  void _showDateTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 350,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1B29),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Set Reminder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                      fontFamily: GoogleFonts.montserrat().fontFamily,
                    ),
                  ),
                  CupertinoButton(
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: GoogleFonts.montserrat().fontFamily,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _reminderDateTime,
                onDateTimeChanged: (dateTime) {
                  setState(() {
                    _reminderDateTime = dateTime;
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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardsProvider);
    final cardsNotifier = ref.read(cardsProvider.notifier);
    final categories = ref.watch(categoryProvider);


    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'New Payment',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap(20),
            AmountInput(),
            Gap(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Payment Method',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
            ),
            Gap(20),
            SizedBox(
              height: 220,
              child: cards.isEmpty
                  ? Center(
                      child: Text('No cards available', style: TextStyle(color: AppColors.textPrimary.withOpacity(0.5))),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return CardPreviewWidget(
                          bankName: card.bankName,
                          balance: card.balance.toString(),
                          isCredit: card.isCredit,
                          isSelected: card.isSelected,
                          onTap: () {
                            cardsNotifier.toggleCardSelection(card.id);
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemCount: cards.length,
                    ),
            ),
            Gap(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Date',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
            ),
            Gap(16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: DatePickerPill()),
            Gap(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Category',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
            ),
            Gap(16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.start,
                children: [
                  ...categories.map((cat) => CategoryChip(iconPath: AppImages.bagShopping, label: cat.label, isSVG: true)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryNeonDark, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.add_circled_solid, color: AppColors.primaryNeonDark),
                        const Gap(8),
                        Text(
                          'Add',
                          style: TextStyle(color: AppColors.primaryNeonDark, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Gap(12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: AppColors.textPrimary.withOpacity(0.5), thickness: 2),
            ),
            Gap(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(color: AppColors.textSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    RecurringPaymentTile(),
                    Gap(16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Frequency',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
                          ),
                          Gap(20),
                          FrequencyDropdown(),
                        ],
                      ),
                    ),
                    Gap(16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notification',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
                              ),
                              Gap(4),
                              Text(
                                'Remind me 1 day before',
                                style: TextStyle(color: AppColors.textPrimary.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w400, fontFamily: GoogleFonts.montserrat().fontFamily),
                              ),
                            ],
                          ),
                          Gap(20),
                          // FrequencyDropdown(),
                          Switch(
                            value: _isReminderEnabled,
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFFE040FB),
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.black26,
                            onChanged: (bool value) {
                              setState(() {
                                _isReminderEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_isReminderEnabled) ...[
                      Gap(16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: InkWell(
                          onTap: _showDateTimePicker,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.time, color: AppColors.primaryNeon, size: 20),
                                Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Reminder Date & Time',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 12,
                                          fontFamily: GoogleFonts.montserrat().fontFamily,
                                        ),
                                      ),
                                      Gap(4),
                                      Text(
                                        DateFormat('MMM dd, yyyy - hh:mm a').format(_reminderDateTime),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: GoogleFonts.montserrat().fontFamily,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(CupertinoIcons.chevron_right, color: Colors.white.withOpacity(0.3), size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    Gap(16),
                  ],
                ),
              ),
            ),
            Gap(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                splashColor: AppColors.textPrimary.withOpacity(0.2),
                highlightColor: AppColors.textPrimary.withOpacity(0.2),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // TODO: add scheduled notification
                  final NotificationService notificationService = NotificationService.instance;
                  notificationService.scheduleNotification(
                    id: Random().nextInt(1000),
                    title: 'Payment Reminder',
                    body: 'Don\'t forget to pay your bill!',
                    scheduledDate: _reminderDateTime,
                  );
                  // TODO: Implement save action
                  // Handle save action
                  print('Transaction Saved!');
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryNeonDark, // Neon green background
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryNeonDark.withOpacity(0.6), // Neon green glow
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'SAVE TRANSACTION',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Gap(60),
          ],
        ),
      ),
    );
  }
}
