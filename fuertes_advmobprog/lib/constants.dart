import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Base URL of the REST API, read from assets/.env at startup.
///
/// Keeping the host out of the source code means the API can be pointed at a
/// different environment without editing (or recompiling) any Dart file.
var host = dotenv.env['HOST'];
