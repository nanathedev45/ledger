import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> configureDatabaseFactory() async {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final supportDirectory = await getApplicationSupportDirectory();
    await databaseFactory.setDatabasesPath(
      path.join(supportDirectory.path, 'databases'),
    );
  }
}
