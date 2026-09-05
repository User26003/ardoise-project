import 'package:intl/intl.dart';

class Fmt {
  static final _num = NumberFormat('#,##0', 'fr_FR');

  /// 45000 -> "45 000 F"
  static String fcfa(int amount) =>
      '${_num.format(amount).replaceAll(',', ' ').replaceAll('\u202f', ' ').replaceAll('\u00a0', ' ')} F';

  /// 45000 -> "45 000"
  static String number(int amount) => _num
      .format(amount)
      .replaceAll(',', ' ')
      .replaceAll('\u202f', ' ')
      .replaceAll('\u00a0', ' ');

  /// Date courte relative : "Auj.", "Hier", "Il y a 3 j", "12 mars"
  static String relativeDate(DateTime? d) {
    if (d == null) return '—';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    if (diff < 7) return 'Il y a $diff j';
    if (d.year == now.year) return DateFormat('d MMM', 'fr_FR').format(d);
    return DateFormat('d MMM yyyy', 'fr_FR').format(d);
  }

  static String fullDate(DateTime d) =>
      DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(d);

  static String dateTime(DateTime d) =>
      DateFormat('d MMM yyyy, HH:mm', 'fr_FR').format(d);

  static String dayLabel(DateTime d) => DateFormat('EEE', 'fr_FR').format(d);

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
}
