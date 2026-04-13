class Validators {
  static bool hasDetectedName({required String fullName}) {
    return fullName.trim().isNotEmpty;
  }

  static bool isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) {
      return false;
    }
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  static bool hasRequiredCheckInFields({
    required String fullName,
    required int? hostId,
    required String hostNameManual,
    required String purpose,
    required bool? hasAppointment,
  }) {
    return fullName.trim().isNotEmpty &&
        ((hostId ?? 0) > 0 || hostNameManual.trim().isNotEmpty) &&
        purpose.trim().isNotEmpty &&
        hasAppointment != null;
  }
}
