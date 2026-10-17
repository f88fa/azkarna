import 'package:intl/intl.dart';

/// Replaces Western digits (0-9) with Arabic-Indic digits (٠-٩).
String arDigits(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  final buffer = StringBuffer();
  for (final unit in input.codeUnits) {
    if (unit >= 0x30 && unit <= 0x39) {
      buffer.write(arabic[unit - 0x30]);
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}

/// Number with Arabic-Indic digits, no grouping.
String arNum(int value) => arDigits('$value');

/// Alias kept for readability where grouping would be wrong (years, etc.).
String arPlain(int value) => arNum(value);

/// Signed number, e.g. `+٢` / `-١` / `٠`.
String arSigned(int value) {
  if (value == 0) return arNum(0);
  return value > 0 ? '+${arNum(value)}' : '-${arNum(-value)}';
}

/// Two-digit zero padded number, e.g. `٠٧`.
String arTwo(int value) => arDigits(value.toString().padLeft(2, '0'));

/// Formats [date] with an Arabic pattern and Arabic-Indic digits.
String arDate(String pattern, DateTime date) =>
    arDigits(DateFormat(pattern, 'ar').format(date));

/// 12-hour time with Arabic digits and ص / م, e.g. `٣:١٧ م`.
String arTime(DateTime time) => arDate('h:mm a', time);

const List<String> hijriMonthsAr = [
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];
