// ENHANCEMENT 2: sign-up form rules, kept as plain functions so they can be
// tested without building a widget or reaching Firebase.

// Rejects an empty field.
String? validateRequired(String? value, String label) =>
    (value == null || value.trim().isEmpty) ? 'Enter your $label' : null;

// Accepts anything shaped like name@domain.tld.
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email address';
  return RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)
      ? null
      : 'Enter a valid email address';
}

// Accepts a whole number a shopper could plausibly be.
String? validateAge(String? value) {
  final age = int.tryParse(value?.trim() ?? '');
  if (age == null) return 'Enter your age';
  return (age < 13 || age > 120) ? 'Age must be between 13 and 120' : null;
}

// Accepts an 11-digit mobile number.
String? validateContactNo(String? value) {
  final contactNo = value?.trim() ?? '';
  if (contactNo.isEmpty) return 'Enter your contact number';
  return RegExp(r'^\d{11}$').hasMatch(contactNo)
      ? null
      : 'Contact number must be 11 digits';
}

// Firebase rejects anything under six characters; this asks for a bit more.
String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Enter a password';
  if (password.length < 8) return 'Password must be at least 8 characters';
  if (!password.contains(RegExp(r'[A-Za-z]')) ||
      !password.contains(RegExp(r'\d'))) {
    return 'Password needs a letter and a number';
  }
  return null;
}

// Checks the second password box against the first.
String? validateConfirmPassword(String? value, String password) =>
    (value ?? '') == password ? null : 'Passwords do not match';
