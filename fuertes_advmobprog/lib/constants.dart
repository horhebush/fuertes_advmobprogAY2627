import 'package:flutter_dotenv/flutter_dotenv.dart';

// Base URL of the API, read from assets/.env so it is not hard coded.
var host = dotenv.env['HOST'];
