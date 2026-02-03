import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import '../core/models/card.dart';
import '../features/cards/widget/card_preview_widget.dart';
import '../features/home/widget/custom_segmented_tab_bar.dart';
import '../providers/providers.dart';

class AppBottomSheet {
  static void showAddCardBottomSheet(BuildContext context, WidgetRef ref) {
    // 0: Debit, 1: Credit, 2: Cash
    int selectedTabIndex = 0;
    final TextEditingController bankNameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController creditLimitController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isCredit = selectedTabIndex == 1;
            final isCash = selectedTabIndex == 2;

            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Gap(24),
                  Text(
                    'Add New Source',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(24),
                  CustomSegmentedTabBar(
                    tabs: const ['Debit', 'Credit', 'Cash'],
                    selectedIndex: selectedTabIndex,
                    onChanged: (index) {
                      setState(() {
                        selectedTabIndex = index;
                        if (index == 2) {
                          bankNameController.text = 'Cash';
                        } else if (bankNameController.text == 'Cash') {
                          bankNameController.clear();
                        }
                      });
                    },
                  ),
                  const Gap(24),
                  CardPreviewWidget(
                    bankName: bankNameController.text,
                    balance: isCredit
                        ? creditLimitController.text
                        : amountController.text,
                    isCredit: isCredit,
                  ),
                  const Gap(24),
                  if (!isCash)
                    _buildField(
                      controller: bankNameController,
                      hint: 'Bank/Provider Name',
                      icon: Icons.account_balance_rounded,
                      onChanged: (val) => setState(() {}),
                    ),
                  if (!isCash) const Gap(16),
                  if (isCredit)
                    _buildField(
                      controller: creditLimitController,
                      hint: 'Credit Limit',
                      icon: Icons.speed_rounded,
                      keyboardType: TextInputType.number,
                      onChanged: (val) => setState(() {}),
                    )
                  else
                    _buildField(
                      controller: amountController,
                      hint: isCash ? 'Initial Cash Amount' : 'Current Balance',
                      icon: Icons.currency_rupee_rounded,
                      keyboardType: TextInputType.number,
                      onChanged: (val) => setState(() {}),
                    ),
                  const Gap(32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = bankNameController.text.trim();
                        final amount =
                            double.tryParse(amountController.text.trim()) ??
                            0.0;
                        final limit =
                            double.tryParse(
                              creditLimitController.text.trim(),
                            ) ??
                            0.0;

                        if (!isCash && name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a bank name'),
                            ),
                          );
                          return;
                        }

                        BankCard card;
                        if (isCash) {
                          card = BankCard.cash(balance: amount);
                        } else if (isCredit) {
                          card = BankCard.credit(
                            bankName: name,
                            creditLimit: limit,
                          );
                        } else {
                          card = BankCard.debit(
                            bankName: name,
                            balance: amount,
                          );
                        }

                        final success = await ref
                            .read(cardsProvider.notifier)
                            .addCard(card);
                        if (success && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('SAVE SOURCE'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void showManageCardsBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String type,
  ) {
    BankCard? selectedCard;
    bool isEditing = false;
    final TextEditingController bankNameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController limitController = TextEditingController();
    final TextEditingController usedController = TextEditingController();

    bool isPrimary = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer(
              builder: (context, ref, _) {
                final cardsState = ref.watch(cardsProvider);
                // Filter by type or accountType for more robust matching
                final filteredCards = cardsState.cards.where((c) {
                  return c.type.toUpperCase() == type.toUpperCase();
                }).toList();

                return Container(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Gap(24),
                      Text(
                        isEditing
                            ? 'Edit ${selectedCard?.accountType.displayName}'
                            : 'Pick a Source',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(24),
                      if (!isEditing)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: filteredCards.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32),
                                  child: Text('Nothing found here'),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: filteredCards.length,
                                  separatorBuilder: (_, __) => const Gap(12),
                                  itemBuilder: (context, index) {
                                    final card = filteredCards[index];
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedCard = card;
                                          isEditing = true;
                                          bankNameController.text =
                                              card.bankName;
                                          amountController.text = card.balance
                                              .toString();
                                          limitController.text = card
                                              .creditLimit
                                              .toString();
                                          usedController.text = card.usedAmount
                                              .toString();
                                          isPrimary = card.isPrimary;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white10,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryNeon
                                                    .withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                card.isCredit
                                                    ? Icons.credit_card
                                                    : Icons
                                                          .account_balance_wallet,
                                                color: AppColors.primaryNeon,
                                                size: 20,
                                              ),
                                            ),
                                            const Gap(16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    card.bankName,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Balance: ₹${card.displayBalance}',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.white24,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        )
                      else ...[
                        CardPreviewWidget(
                          bankName: bankNameController.text,
                          balance: selectedCard!.isCredit
                              ? limitController.text
                              : amountController.text,
                          isCredit: selectedCard!.isCredit,
                        ),
                        const Gap(24),
                        if (!selectedCard!.isCash)
                          _buildField(
                            controller: bankNameController,
                            hint: 'Bank Name',
                            icon: Icons.account_balance_rounded,
                            onChanged: (val) => setState(() {}),
                          ),
                        const Gap(16),
                        if (selectedCard!.isCredit) ...[
                          _buildField(
                            controller: limitController,
                            hint: 'Limit',
                            icon: Icons.speed_rounded,
                            keyboardType: TextInputType.number,
                            onChanged: (val) => setState(() {}),
                          ),
                          const Gap(16),
                          _buildField(
                            controller: usedController,
                            hint: 'Spent Amount',
                            icon: Icons.shopping_bag_outlined,
                            keyboardType: TextInputType.number,
                            onChanged: (val) => setState(() {}),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildField(
                                  controller: amountController,
                                  hint: 'Balance',
                                  icon: Icons.currency_rupee_rounded,
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) => setState(() {}),
                                ),
                              ),
                              if (selectedCard!.isDebit) ...[
                                const Gap(16),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CupertinoCheckbox(
                                      value: isPrimary,
                                      onChanged: (val) =>
                                          setState(() => isPrimary = val!),
                                      activeColor: AppColors.primaryNeon,
                                    ),
                                    Text(
                                      'Primary',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                        const Gap(32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => isEditing = false),
                                child: const Text('BACK'),
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (selectedCard != null) {
                                    final updatedCard = selectedCard!.copyWith(
                                      bankName: bankNameController.text.trim(),
                                      balance:
                                          double.tryParse(
                                            amountController.text.trim(),
                                          ) ??
                                          0.0,
                                      creditLimit:
                                          double.tryParse(
                                            limitController.text.trim(),
                                          ) ??
                                          0.0,
                                      usedAmount:
                                          double.tryParse(
                                            usedController.text.trim(),
                                          ) ??
                                          0.0,
                                      isPrimary: isPrimary,
                                    );

                                    await ref
                                        .read(cardsProvider.notifier)
                                        .updateCard(updatedCard);

                                    if (isPrimary && selectedCard!.isDebit) {
                                      await ref
                                          .read(cardsProvider.notifier)
                                          .setPrimaryCard(updatedCard.id!);
                                    }

                                    if (context.mounted) Navigator.pop(context);
                                  }
                                },
                                child: const Text('UPDATE'),
                              ),
                            ),
                          ],
                        ),
                        const Gap(12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () async {
                              final confirm = await _showDeleteConfirm(
                                context,
                                selectedCard!.bankName,
                              );
                              if (confirm == true) {
                                await ref
                                    .read(cardsProvider.notifier)
                                    .deleteCard(selectedCard!.id!);
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.errorRed,
                            ),
                            label: const Text(
                              'Delete Card',
                              style: TextStyle(color: AppColors.errorRed),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static Future<bool?> _showDeleteConfirm(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Source?'),
        content: Text('Remove $name and all its data? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  static Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.montserrat(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryNeon, size: 20),
      ),
    );
  }
}
