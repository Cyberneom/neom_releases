
import 'package:neom_commons/core/domain/model/price.dart';

class CommerceUtilities {

  static Price? getPriceWithDiscount(Price? currentPrice, double? discount) {
    if(discount == null) return currentPrice;
    if(currentPrice != null) {
      currentPrice.amount = currentPrice.amount - (currentPrice.amount * discount);
    }
    return currentPrice;
  }

  static String getFormattedDiscountPercentage(double discountPercentage) {
    // Convertimos el número a una cadena con dos decimales
    String formattedPercentage = discountPercentage.toStringAsFixed(2);

    // Eliminamos los decimales si son ceros
    if (formattedPercentage.endsWith('.00')) {
      formattedPercentage = formattedPercentage.substring(0, formattedPercentage.length - 3);
    }

    return formattedPercentage;
  }

}
