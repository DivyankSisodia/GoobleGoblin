import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/DB/db_helper.dart';

/// Toggles visibility of sensitive balance/amount values across the app.
/// true = visible, false = hidden (shows ••••••).
final balanceVisibilityProvider = StateProvider<bool>((ref) => true);

/// Fetches the monthly budget from the database.
final monthlyBudgetProvider = FutureProvider<double>((ref) async {
  return DatabaseHelper.instance.getMonthlyBudget();
});
