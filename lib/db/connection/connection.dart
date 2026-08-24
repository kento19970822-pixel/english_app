// コード管理番号: VER-20260825-04
import 'package:drift/drift.dart';

import 'unsupported.dart'
    if (dart.library.ffi) 'native.dart'
    if (dart.library.js_interop) 'web.dart'
    if (dart.library.html) 'web.dart' as impl;

DatabaseConnection connect() => impl.connect();
