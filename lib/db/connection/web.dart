// コード管理番号: VER-20260825-06
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

DatabaseConnection connect() {
  return DatabaseConnection(
    LazyDatabase(() async {
      final result = await WasmDatabase.open(
        databaseName: 'english_app_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
      return result.resolvedExecutor;
    }),
  );
}
