import 'package:intl/intl.dart';

class CurrencyUtil {
  static const symbol = 'руб';

  static String formatPrice(double price) {
    return '${NumberFormat('#,###.##').format(price)} $symbol';
  }

  static String formatTotal(int quantity, double unitPrice) {
    return formatPrice(quantity * unitPrice);
  }
}
