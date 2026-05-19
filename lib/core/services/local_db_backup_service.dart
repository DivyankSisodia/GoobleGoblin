import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../DB/db_helper.dart';

class LocalDbBackupExport {
  final String json;
  final String path;
  final int bytes;

  const LocalDbBackupExport({
    required this.json,
    required this.path,
    required this.bytes,
  });
}

class LocalDbBackupService {
  LocalDbBackupService({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<LocalDbBackupExport> exportToJsonFile() async {
    final snapshot = await _dbHelper.exportLocalDbSnapshot();
    const encoder = JsonEncoder.withIndent('  ');
    final json = encoder.convert(snapshot);
    final directory =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${directory.path}/gooble_goblin_backup_$timestamp.json');
    await file.writeAsString(json);

    return LocalDbBackupExport(
      json: json,
      path: file.path,
      bytes: await file.length(),
    );
  }

  Future<void> importFromJsonString(String json) async {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup JSON must be an object');
    }

    await _dbHelper.importLocalDbSnapshot(decoded);
  }
}
