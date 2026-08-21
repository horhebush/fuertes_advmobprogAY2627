import 'package:flutter_dotenv/flutter_dotenv.dart';

// Base URL of the API, read from assets/.env.
var host = dotenv.env['HOST'];

// ENHANCEMENT 3: the cart owner, until sign-in supplies the real one.
const defaultUserId = 5;
