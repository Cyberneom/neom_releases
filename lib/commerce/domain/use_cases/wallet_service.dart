import 'package:flutter/material.dart';

import 'package:neom_commons/core/utils/enums/app_currency.dart';
import '../models/app_product.dart';

abstract class WalletService {

  void changeAppCoinProduct(AppProduct selectedProduct);
  void setActualCurrency({required AppCurrency productCurrency});
  void changePaymentCurrency({required AppCurrency newCurrency});
  void changePaymentAmount({double newAmount = 0});
  Future<void> payAppProduct(BuildContext context);

}
