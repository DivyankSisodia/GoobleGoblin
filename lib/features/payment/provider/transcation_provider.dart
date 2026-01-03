import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gooble_goblin/core/models/payment.dart';

import '../../../core/DB/db_helper.dart';

class TransactionNotifier extends StateNotifier<List<Payment>> {
  TransactionNotifier() : super([]){
    fetchPayments();
  }

  Future<List<Payment>> fetchPayments() async {
    // TODO: implement fetch payments
    final transcations = await DatabaseHelper.instance.getAllPayments();
    state = transcations;
    return transcations;
  }

  Future<void> addPayment(Payment payment) async {
    await DatabaseHelper.instance.insertPayment(payment);
    await fetchPayments();
  }

  Future<void> updatePayment(Payment payment) async {
    await DatabaseHelper.instance.updatePayment(payment);
    await fetchPayments();
  }

  Future<void> deletePayment(int id) async {
    await DatabaseHelper.instance.deletePayment(id);
    await fetchPayments();
  }

  Future<List<Payment>> getPaymentByCategory(String category) async {
    final payment = await DatabaseHelper.instance.getPaymentByCategory(category);
    return payment;
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<Payment>>((ref) {
  return TransactionNotifier();
});
