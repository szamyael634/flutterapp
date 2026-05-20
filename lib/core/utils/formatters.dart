import 'package:intl/intl.dart';

class AppFormatters {
  static final _currency = NumberFormat.currency(
    locale: 'en_PH',
    symbol: 'PHP ',
    decimalDigits: 2,
  );

  static final _shortDate = DateFormat('MMM d, h:mm a');

  static String currency(num value) => _currency.format(value);

  static String shortDate(DateTime value) => _shortDate.format(value.toLocal());
}
