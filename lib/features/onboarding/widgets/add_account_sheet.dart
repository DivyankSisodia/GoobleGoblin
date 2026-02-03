import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/card.dart';

/// Bottom sheet for adding new account during onboarding
class AddAccountSheet extends StatefulWidget {
  final AccountType type;
  final void Function(BankCard card) onSave;

  const AddAccountSheet({super.key, required this.type, required this.onSave});

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  final _bankNameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _limitController = TextEditingController();
  final _usedController = TextEditingController();

  String get _title {
    switch (widget.type) {
      case AccountType.cash:
        return 'Add Cash';
      case AccountType.debit:
        return 'Add Bank Account';
      case AccountType.credit:
        return 'Add Credit Card';
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case AccountType.cash:
        return Icons.money_rounded;
      case AccountType.debit:
        return Icons.account_balance_rounded;
      case AccountType.credit:
        return Icons.credit_card_rounded;
    }
  }

  Color get _color {
    switch (widget.type) {
      case AccountType.cash:
        return AppColors.successGreen;
      case AccountType.debit:
        return AppColors.accentBlue;
      case AccountType.credit:
        return AppColors.accentMagenta;
    }
  }

  bool get _isValid {
    switch (widget.type) {
      case AccountType.cash:
        return _balanceController.text.isNotEmpty;
      case AccountType.debit:
        return _bankNameController.text.isNotEmpty &&
            _balanceController.text.isNotEmpty;
      case AccountType.credit:
        return _bankNameController.text.isNotEmpty &&
            _limitController.text.isNotEmpty;
    }
  }

  void _save() {
    if (!_isValid) return;

    BankCard card;
    switch (widget.type) {
      case AccountType.cash:
        card = BankCard.cash(
          balance: double.tryParse(_balanceController.text) ?? 0,
        );
        break;
      case AccountType.debit:
        card = BankCard.debit(
          bankName: _bankNameController.text.trim(),
          balance: double.tryParse(_balanceController.text) ?? 0,
        );
        break;
      case AccountType.credit:
        card = BankCard.credit(
          bankName: _bankNameController.text.trim(),
          creditLimit: double.tryParse(_limitController.text) ?? 0,
          usedAmount: double.tryParse(_usedController.text) ?? 0,
        );
        break;
    }

    widget.onSave(card);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(24),

            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: _color, size: 24),
                ),
                const Gap(16),
                Text(
                  _title,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Gap(32),

            // Bank name (not for cash)
            if (widget.type != AccountType.cash) ...[
              _buildLabel('Bank Name'),
              const Gap(8),
              _buildTextField(
                controller: _bankNameController,
                hint: 'e.g., HDFC Bank',
                icon: Icons.business_rounded,
              ),
              const Gap(20),
            ],

            // Balance (for cash and debit)
            if (widget.type != AccountType.credit) ...[
              _buildLabel(
                widget.type == AccountType.cash
                    ? 'Cash Amount'
                    : 'Current Balance',
              ),
              const Gap(8),
              _buildAmountField(controller: _balanceController, hint: '10,000'),
              const Gap(20),
            ],

            // Credit limit (for credit)
            if (widget.type == AccountType.credit) ...[
              _buildLabel('Credit Limit'),
              const Gap(8),
              _buildAmountField(controller: _limitController, hint: '1,00,000'),
              const Gap(20),
              _buildLabel('Current Used Amount (Optional)'),
              const Gap(8),
              _buildAmountField(controller: _usedController, hint: '0'),
              const Gap(20),
            ],

            // Save button
            const Gap(12),
            GestureDetector(
              onTap: _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _isValid ? AppColors.analyticsGradient : null,
                  color: _isValid ? null : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Add ${widget.type.displayName}',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: _isValid ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 12,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(
            fontSize: 16,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Text(
              '₹',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNeon,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _balanceController.dispose();
    _limitController.dispose();
    _usedController.dispose();
    super.dispose();
  }
}
