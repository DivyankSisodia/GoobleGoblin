import '../DB/db_helper.dart';

class BankStatementImport {
  static Future<void> importIfNeeded() async {
    final db = await DatabaseHelper.instance.database;

    final setting = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['bank_statement_imported'],
    );
    if (setting.isNotEmpty) return;

    final cards = await db.query(
      'cards',
      where: 'COALESCE(isDeleted, 0) = 0',
    );
    if (cards.isEmpty) return;

    final cardId = cards.first['id'] as int;

    final categories = await db.query(
      'categories',
      where: 'COALESCE(isDeleted, 0) = 0',
    );
    final catMap = <String, int>{};
    for (final c in categories) {
      catMap[c['label'] as String] = c['id'] as int;
    }

    final subcategories = await db.query(
      'subcategories',
      where: 'COALESCE(isDeleted, 0) = 0',
    );
    final subMap = <String, int>{};
    for (final s in subcategories) {
      subMap[s['label'] as String] = s['id'] as int;
    }

    final transactions = _getTransactions();

    for (final t in transactions) {
      final isIncome = t['credit'] as double > 0;
      final amount = t['amount'] as double;
      final dateStr = t['date'] as String;
      final note = t['note'] as String;

      final parsed = _parseDate(dateStr);
      final catInfo = _categorize(note, isIncome);
      final categoryId = catMap[catInfo['category']];
      final subcategoryId = subMap[catInfo['subcategory']];

      if (categoryId == null) continue;

      await db.insert('payments', {
        'amount': amount,
        'date': parsed,
        'isRecurring': 0,
        'frequency': null,
        'reminderNotification': 0,
        'note': note,
        'cardId': cardId,
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,
        'isExternalTransaction': 0,
        'isIncome': isIncome ? 1 : 0,
        'createdAt': parsed,
        'syncStatus': 'PENDING_CREATE',
        'isDeleted': 0,
      });

      final card = cards.first;
      final cardType = card['accountType'] as String? ?? 'DEBIT';
      final now = DateTime.now().toIso8601String();

      if (isIncome) {
        if (cardType == 'CREDIT') {
          await db.execute(
            'UPDATE cards SET usedAmount = MAX(0, usedAmount - ?), updatedAt = ? WHERE id = ?',
            [amount, now, cardId],
          );
        } else {
          await db.execute(
            'UPDATE cards SET balance = balance + ?, updatedAt = ? WHERE id = ?',
            [amount, now, cardId],
          );
        }
      } else {
        if (cardType == 'CREDIT') {
          await db.execute(
            'UPDATE cards SET usedAmount = usedAmount + ?, updatedAt = ? WHERE id = ?',
            [amount, now, cardId],
          );
        } else {
          await db.execute(
            'UPDATE cards SET balance = balance - ?, updatedAt = ? WHERE id = ?',
            [amount, now, cardId],
          );
        }
      }
    }

    await db.insert('app_settings', {
      'key': 'bank_statement_imported',
      'value': 'true',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static String _parseDate(String date) {
    final parts = date.split('/');
    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = '20${parts[2]}';
    return '$year-$month-${day}T00:00:00.000';
  }

  static Map<String, String> _categorize(String note, bool isIncome) {
    final n = note.toUpperCase();

    if (n.contains('ZOMATO')) return {'category': 'Food & Grocery', 'subcategory': 'Zomato'};
    if (n.contains('ZEPTO')) return {'category': 'Food & Grocery', 'subcategory': 'Zepto'};
    if (n.contains('AMAZON') && n.contains('GROCER')) return {'category': 'Food & Grocery', 'subcategory': 'Amazon'};
    if (n.contains('AMAZON')) return {'category': 'Shopping', 'subcategory': 'Amazon'};
    if (n.contains('FLIPKART')) return {'category': 'Shopping', 'subcategory': 'Flipkart'};
    if (n.contains('NETFLIX')) return {'category': 'Subscriptions', 'subcategory': 'Netflix'};
    if (n.contains('SPOTIFY')) return {'category': 'Subscriptions', 'subcategory': 'Spotify'};
    if (n.contains('CRED') && n.contains('CLUB')) return {'category': 'Bills', 'subcategory': ''};
    if (n.contains('IDFC') || n.contains('ACH D')) return {'category': 'Bills', 'subcategory': 'Loan'};
    if (n.contains('GLOBAL PETRO') || n.contains('DRIVE N FILL')) return {'category': 'Bike', 'subcategory': ''};
    if (n.contains('GOOGLE INDIA') && n.contains('RECHARGE')) return {'category': 'Subscriptions', 'subcategory': 'Mobile'};
    if (n.contains('GOOGLE INDIA')) return {'category': 'Subscriptions', 'subcategory': 'Mobile'};
    if (n.contains('GITHUB')) return {'category': 'Subscriptions', 'subcategory': 'Llm'};
    if (n.contains('ANOMALY') && n.contains('AUTOPAY')) return {'category': 'Subscriptions', 'subcategory': 'Llm'};
    if (n.contains('FURLENCO')) return {'category': 'Miscellaneous', 'subcategory': ''};
    if (n.contains('EYE WORLD')) return {'category': 'Miscellaneous', 'subcategory': ''};
    if (n.contains('SALARY')) return {'category': 'Miscellaneous', 'subcategory': ''};
    if (n.contains('DC INTL') || n.contains('POS')) return {'category': 'Shopping', 'subcategory': ''};

    if (isIncome) return {'category': 'Miscellaneous', 'subcategory': 'Money Transfer'};
    return {'category': 'Miscellaneous', 'subcategory': ''};
  }

  static List<Map<String, dynamic>> _getTransactions() {
    return [
      {'date': '01/05/26', 'note': 'UPI-SUBHASH CHAND-PAYTMQR6ANRSS@PTYS', 'amount': 50.0, 'debit': 50.0, 'credit': 0.0},
      {'date': '01/05/26', 'note': 'UPI-BHASKER NATH TIWARI-Q504414432@YBL', 'amount': 45.0, 'debit': 45.0, 'credit': 0.0},
      {'date': '01/05/26', 'note': 'UPI-BAL KRISHAN SISODIA-Transfer', 'amount': 6000.0, 'debit': 0.0, 'credit': 6000.0},
      {'date': '01/05/26', 'note': 'UPI-MISS NEHA-9999027290@YBL', 'amount': 160.0, 'debit': 160.0, 'credit': 0.0},
      {'date': '01/05/26', 'note': 'UPI-VINOD MANDAL-Q532181616@YBL', 'amount': 96.0, 'debit': 96.0, 'credit': 0.0},
      {'date': '02/05/26', 'note': 'DC INTL POS TXN MARKUP', 'amount': 104.25, 'debit': 104.25, 'credit': 0.0},
      {'date': '02/05/26', 'note': 'UPI-CRED CLUB-CRED.CLUB@AXISB', 'amount': 1544.0, 'debit': 1544.0, 'credit': 0.0},
      {'date': '02/05/26', 'note': 'UPI-ZOMATO LTD-ZOMATOLTD32.RZP@HDFCBANK', 'amount': 159.75, 'debit': 159.75, 'credit': 0.0},
      {'date': '02/05/26', 'note': 'UPI-ANAND KUMAR-PAYTM.S25KNZH@PTY', 'amount': 100.0, 'debit': 100.0, 'credit': 0.0},
      {'date': '02/05/26', 'note': 'UPI-GLOBAL PETRO IOCL-PAYTMQR65QJES@PTYS', 'amount': 500.0, 'debit': 500.0, 'credit': 0.0},
      {'date': '03/05/26', 'note': 'ACH D- IDFC FIRST BANK-EMI', 'amount': 5984.0, 'debit': 5984.0, 'credit': 0.0},
      {'date': '05/05/26', 'note': 'UPI-BAL KRISHAN SISODIA-Transfer', 'amount': 650.0, 'debit': 0.0, 'credit': 650.0},
      {'date': '05/05/26', 'note': 'UPI-MANOJ-PAYTM.S2331SW@PTY', 'amount': 90.0, 'debit': 90.0, 'credit': 0.0},
      {'date': '05/05/26', 'note': 'UPI-FURLENCO-FURLENCO908602.RZP', 'amount': 664.68, 'debit': 664.68, 'credit': 0.0},
      {'date': '05/05/26', 'note': 'UPI-AMAZON PAY GROCERIES', 'amount': 179.0, 'debit': 179.0, 'credit': 0.0},
      {'date': '06/05/26', 'note': 'UPI-ASHISH KUMAR PALIWAL-Transfer', 'amount': 1000.0, 'debit': 1000.0, 'credit': 0.0},
      {'date': '07/05/26', 'note': 'NEFT CR-SALARY-DIVYANK SISODIA', 'amount': 70834.0, 'debit': 0.0, 'credit': 70834.0},
      {'date': '08/05/26', 'note': 'UPI-KIRAN YADAV-KY811504@OKHDFCBANK', 'amount': 5000.0, 'debit': 5000.0, 'credit': 0.0},
      {'date': '08/05/26', 'note': 'UPI-RUPA RANI-BHARATPE-Transfer', 'amount': 55.0, 'debit': 55.0, 'credit': 0.0},
      {'date': '08/05/26', 'note': 'UPI-ZOMATO-PAYZOMATO@HDFCBANK', 'amount': 148.83, 'debit': 148.83, 'credit': 0.0},
      {'date': '08/05/26', 'note': 'UPI-RAM KRIPALU NEELMANI-Transfer', 'amount': 516.0, 'debit': 0.0, 'credit': 516.0},
      {'date': '08/05/26', 'note': 'UPI-ZOMATO LIMITED-ZOMATO-ORDER@PTYBL', 'amount': 505.42, 'debit': 505.42, 'credit': 0.0},
      {'date': '09/05/26', 'note': 'UPI-MISS NEHA-9999027290@YBL', 'amount': 80.0, 'debit': 80.0, 'credit': 0.0},
      {'date': '09/05/26', 'note': 'UPI-NISHANT KUMAR-Transfer', 'amount': 20.0, 'debit': 20.0, 'credit': 0.0},
      {'date': '10/05/26', 'note': 'UPI-BAL KRISHAN SISODIA-Transfer', 'amount': 52500.0, 'debit': 52500.0, 'credit': 0.0},
      {'date': '10/05/26', 'note': 'CRV POS-GITHUB, IN', 'amount': 2551.34, 'debit': 0.0, 'credit': 2551.34},
      {'date': '11/05/26', 'note': 'UPI-AUTOPAY-ANOMALY-ANOMALY.CFP@CASHFREE', 'amount': 464.5, 'debit': 464.5, 'credit': 0.0},
      {'date': '11/05/26', 'note': 'UPI-ZOMATO-PAYZOMATO@HDFCBANK', 'amount': 231.78, 'debit': 231.78, 'credit': 0.0},
      {'date': '12/05/26', 'note': 'UPI-SUSHIL KUMAR-Transfer', 'amount': 1000.0, 'debit': 1000.0, 'credit': 0.0},
      {'date': '12/05/26', 'note': 'UPI-AMIT-Transfer', 'amount': 66.0, 'debit': 66.0, 'credit': 0.0},
      {'date': '13/05/26', 'note': 'UPI-ZOMATO-PAYZOMATO@HDFCBANK', 'amount': 383.8, 'debit': 383.8, 'credit': 0.0},
      {'date': '13/05/26', 'note': 'UPI-SHIV PRASAD-Transfer', 'amount': 80.0, 'debit': 80.0, 'credit': 0.0},
      {'date': '13/05/26', 'note': 'UPI-JULIDEVI DEVI-Transfer', 'amount': 30.0, 'debit': 30.0, 'credit': 0.0},
      {'date': '13/05/26', 'note': 'UPI-ANKIT JAIN-Transfer', 'amount': 20.0, 'debit': 20.0, 'credit': 0.0},
      {'date': '13/05/26', 'note': 'UPI-ANSHUL SAINI-Transfer', 'amount': 500.0, 'debit': 500.0, 'credit': 0.0},
      {'date': '14/05/26', 'note': 'UPI-SUSHIL KUMAR-Transfer received', 'amount': 1000.0, 'debit': 0.0, 'credit': 1000.0},
      {'date': '14/05/26', 'note': 'UPI-EYE WORLD-GPAY-11209101263@OKBIZAXIS', 'amount': 100.0, 'debit': 100.0, 'credit': 0.0},
      {'date': '14/05/26', 'note': 'UPI-SUSHIL KUMAR-Transfer', 'amount': 224.0, 'debit': 224.0, 'credit': 0.0},
      {'date': '15/05/26', 'note': 'UPI-ZOMATO-PAYZOMATO@HDFCBANK', 'amount': 282.18, 'debit': 282.18, 'credit': 0.0},
      {'date': '16/05/26', 'note': 'UPI-DRIVE N FILL-PAYTMQR65R9MB@PTYS', 'amount': 500.0, 'debit': 500.0, 'credit': 0.0},
      {'date': '18/05/26', 'note': 'UPI-ZEPTO MARKETPLACE-Transfer', 'amount': 250.0, 'debit': 250.0, 'credit': 0.0},
      {'date': '18/05/26', 'note': 'UPI-PIYUSH KUMAR-Transfer', 'amount': 250.0, 'debit': 250.0, 'credit': 0.0},
      {'date': '18/05/26', 'note': 'UPI-SHREE LAKSHMI GENERA-GPAY', 'amount': 36.0, 'debit': 36.0, 'credit': 0.0},
      {'date': '18/05/26', 'note': 'UPI-RUPA RANI-Transfer', 'amount': 70.0, 'debit': 70.0, 'credit': 0.0},
      {'date': '19/05/26', 'note': 'UPI-GOOGLE INDIA DIGITAL-Recharge', 'amount': 649.0, 'debit': 649.0, 'credit': 0.0},
      {'date': '19/05/26', 'note': 'UPI-AUTOPAY-SPOTIFY INDIA PVT LT', 'amount': 69.0, 'debit': 69.0, 'credit': 0.0},
      {'date': '20/05/26', 'note': 'UPI-AMAZON PAY BALANCE', 'amount': 131.0, 'debit': 131.0, 'credit': 0.0},
      {'date': '20/05/26', 'note': 'UPI-NISHITA SISODIA-Transfer received', 'amount': 200.0, 'debit': 0.0, 'credit': 200.0},
      {'date': '20/05/26', 'note': 'UPI-SHREE LAKSHMI GENERA-GPAY', 'amount': 20.0, 'debit': 20.0, 'credit': 0.0},
      {'date': '20/05/26', 'note': 'UPI-ASHOK KUMAR MAURYA-Transfer', 'amount': 20.0, 'debit': 20.0, 'credit': 0.0},
      {'date': '20/05/26', 'note': 'UPI-RAJU IRON CLOTHES-GPAY', 'amount': 96.0, 'debit': 96.0, 'credit': 0.0},
      {'date': '20/05/26', 'note': 'UPI-SUBHASH CHAND-Transfer', 'amount': 36.0, 'debit': 36.0, 'credit': 0.0},
      {'date': '22/05/26', 'note': 'UPI-AUTOPAY-NETFLIX COM', 'amount': 199.0, 'debit': 199.0, 'credit': 0.0},
      {'date': '22/05/26', 'note': 'UPI-RUPA RANI-Transfer', 'amount': 85.0, 'debit': 85.0, 'credit': 0.0},
      {'date': '22/05/26', 'note': 'UPI-RACHIT-Transfer', 'amount': 300.0, 'debit': 300.0, 'credit': 0.0},
      {'date': '24/05/26', 'note': 'UPI-NISHITA SISODIA-Transfer', 'amount': 200.0, 'debit': 200.0, 'credit': 0.0},
      {'date': '24/05/26', 'note': 'UPI-MANOJ-Transfer', 'amount': 30.0, 'debit': 30.0, 'credit': 0.0},
      {'date': '24/05/26', 'note': 'UPI-ZEPTO MARKETPLACE-PAID VIA CRED', 'amount': 149.0, 'debit': 149.0, 'credit': 0.0},
      {'date': '24/05/26', 'note': 'UPI-DIVYANK SISODIA-Transfer received', 'amount': 1500.0, 'debit': 0.0, 'credit': 1500.0},
      {'date': '25/05/26', 'note': 'UPI-ZOMATO-PAYZOMATO@HDFCBANK', 'amount': 156.0, 'debit': 156.0, 'credit': 0.0},
      {'date': '26/05/26', 'note': 'UPI-DEEPAK KUMAR AGGARWA-Transfer', 'amount': 20.0, 'debit': 20.0, 'credit': 0.0},
      {'date': '26/05/26', 'note': 'UPI-RACHIT-Transfer', 'amount': 50.0, 'debit': 50.0, 'credit': 0.0},
      {'date': '26/05/26', 'note': 'UPI-DRIVE N FILL-PAYTMQR6XAUSN@PTYS', 'amount': 895.0, 'debit': 895.0, 'credit': 0.0},
      {'date': '26/05/26', 'note': 'UPI-ZEPTO MARKETPLACE-PAID VIA CRED', 'amount': 168.0, 'debit': 168.0, 'credit': 0.0},
      {'date': '27/05/26', 'note': 'UPI-SUBHASH CHAND-Transfer', 'amount': 50.0, 'debit': 50.0, 'credit': 0.0},
      {'date': '27/05/26', 'note': 'UPI-SANTOSH KUMAR-Transfer', 'amount': 90.0, 'debit': 90.0, 'credit': 0.0},
      {'date': '29/05/26', 'note': 'UPI-ZOMATO-PAYZOMATO@HDFCBANK', 'amount': 398.59, 'debit': 398.59, 'credit': 0.0},
      {'date': '30/05/26', 'note': 'UPI-GOOGLE INDIA DIGITAL-Reward', 'amount': 1.0, 'debit': 0.0, 'credit': 1.0},
      {'date': '30/05/26', 'note': 'UPI-GOOGLE INDIA DIGITAL-Reward', 'amount': 1.0, 'debit': 0.0, 'credit': 1.0},
      {'date': '30/05/26', 'note': 'UPI-GOOGLE INDIA DIGITAL-Rewarded for trans', 'amount': 6.0, 'debit': 0.0, 'credit': 6.0},
      {'date': '30/05/26', 'note': 'UPI-GOOGLE INDIA DIGITAL-Reward', 'amount': 2.0, 'debit': 0.0, 'credit': 2.0},
      {'date': '30/05/26', 'note': 'UPI-MANOJ-Transfer', 'amount': 50.0, 'debit': 50.0, 'credit': 0.0},
      {'date': '31/05/26', 'note': 'UPI-DIVYANK SISODIA-Transfer received', 'amount': 6000.0, 'debit': 0.0, 'credit': 6000.0},
    ];
  }
}