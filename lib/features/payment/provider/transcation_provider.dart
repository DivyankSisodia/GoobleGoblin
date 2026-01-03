import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gooble_goblin/core/models/payment.dart';

import '../../../core/DB/db_helper.dart';

import 'package:gooble_goblin/features/home/provider/cards_provider.dart';

class TransactionNotifier extends StateNotifier<List<Payment>> {
  final Ref _ref;
  
  TransactionNotifier(this._ref) : super([]){
    fetchPayments();
  }

  Future<List<Payment>> fetchPayments() async {
    final transcations = await DatabaseHelper.instance.getAllPayments();
    state = transcations;
    return transcations;
  }

  Future<void> addPayment(Payment payment) async {
    await DatabaseHelper.instance.insertPayment(payment);
    await fetchPayments();
    // Refresh cards to update balances
    _ref.read(cardsProvider.notifier).loadCards();
  }

  Future<void> updatePayment(Payment payment) async {
    await DatabaseHelper.instance.updatePayment(payment);
    await fetchPayments();
    // Refresh cards to update balances
    _ref.read(cardsProvider.notifier).loadCards();
  }

  Future<void> deletePayment(int id) async {
    await DatabaseHelper.instance.deletePayment(id);
    await fetchPayments();
    // Refresh cards to update balances
    _ref.read(cardsProvider.notifier).loadCards();
  }

  Future<List<Payment>> getPaymentByCategory(String category) async {
    final payment = await DatabaseHelper.instance.getPaymentByCategory(category);
    return payment;
  }

  Future<void> refreshList() async {
    await fetchPayments();
  }

  Future<List<Payment>> getRecurringPayment() async {
    final payment = await DatabaseHelper.instance.getRecurringPayment();
    return payment;
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<Payment>>((ref) {
  return TransactionNotifier(ref);
});

final recurringPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  // Watch transactionProvider to automatically refresh when payments change
  final allPayments = ref.watch(transactionProvider);
  
  // Return only recurring payments from the current state
  return allPayments.where((p) => p.isRecurring).toList();
});
