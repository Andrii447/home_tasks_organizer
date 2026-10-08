const _months = [
  'січня',
  'лютого',
  'березня',
  'квітня',
  'травня',
  'червня',
  'липня',
  'серпня',
  'вересня',
  'жовтня',
  'листопада',
  'грудня',
];

/// «30 вересня»
String formatShortDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]}';

/// «30.09.2026»
String formatNumericDate(DateTime date) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}';
}
