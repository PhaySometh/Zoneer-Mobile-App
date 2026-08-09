import 'package:intl/intl.dart';

class MessageDateFormatter {
  const MessageDateFormatter._();

  static DateTime? _parseToLocalDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(value);
    return parsed?.toLocal();
  }

  static String formatConversationDate(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }

    final localDate = _parseToLocalDateTime(value);
    if (localDate == null) {
      return value;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(localDate.year, localDate.month, localDate.day);
    final differenceInDays = today.difference(messageDay).inDays;

    if (differenceInDays == 0) {
      return DateFormat('h:mm a').format(localDate);
    }

    if (differenceInDays == 1) {
      return 'Yesterday';
    }

    if (localDate.year == now.year) {
      return DateFormat('MMM d').format(localDate);
    }

    return DateFormat('MMM d, y').format(localDate);
  }

  static String formatMessageTime(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }

    final localDate = _parseToLocalDateTime(value);
    if (localDate == null) {
      return value;
    }

    return DateFormat('h:mm a').format(localDate);
  }

  static String formatDayHeader(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }

    final localDate = _parseToLocalDateTime(value);
    if (localDate == null) {
      return value;
    }

    final now = DateTime.now();
    if (localDate.year == now.year) {
      return DateFormat('MMM, dd').format(localDate);
    }

    return DateFormat('MMM, dd, yyyy').format(localDate);
  }

  static bool isDifferentDay(String? currentValue, String? previousValue) {
    final current = _parseToLocalDateTime(currentValue);
    final previous = _parseToLocalDateTime(previousValue);

    if (current == null || previous == null) {
      return true;
    }

    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }
}
