import 'package:intl/intl.dart';

class DateTimeFormatter {
  static String shortTime(DateTime? value) {
    if (value == null) {
      return '--:--';
    }
    return DateFormat('HH:mm').format(value);
  }

  static String shortDate(DateTime? value) {
    if (value == null) {
      return '--/--/----';
    }
    return DateFormat('dd/MM/yyyy').format(value);
  }

  static String dateTime(DateTime? value) {
    if (value == null) {
      return '--/--/---- --:--';
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(value);
  }
}
