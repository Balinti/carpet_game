/// Pure sign-up validation (no BuildContext) so it can be unit-tested.
/// Each returns null when valid, otherwise a [FieldError].
enum FieldError {
  nameRequired,
  emailInvalid,
  passwordTooShort,
  ageInvalid,
}

const int kMinPasswordLength = 6;
const int kMinAge = 4;
const int kMaxAge = 99;

final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

FieldError? validateName(String? v) =>
    (v == null || v.trim().isEmpty) ? FieldError.nameRequired : null;

FieldError? validateEmail(String? v) =>
    (v == null || !_emailPattern.hasMatch(v.trim()))
        ? FieldError.emailInvalid
        : null;

FieldError? validatePassword(String? v) =>
    (v == null || v.length < kMinPasswordLength)
        ? FieldError.passwordTooShort
        : null;

/// Parses the age field; null if not a whole number in [kMinAge]..[kMaxAge].
int? parseAge(String? v) {
  final n = int.tryParse((v ?? '').trim());
  if (n == null || n < kMinAge || n > kMaxAge) return null;
  return n;
}

FieldError? validateAge(String? v) =>
    parseAge(v) == null ? FieldError.ageInvalid : null;
