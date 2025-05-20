import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../../../commerce/domain/models/app_product.dart';
import '../../../commerce/ui/widgets/wallet_widgets.dart';
import '../wallet/wallet_controller.dart';

void showGetAppcoinsAlert(BuildContext context, WalletController _) {
  Alert(
      context: context,
      style: AlertStyle(
          backgroundColor: AppColor.main50,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          titleTextAlign: TextAlign.justify
      ),
      title: AppTranslationConstants.acquireAppCoinsMsg.tr,
      content: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${AppTranslationConstants.appCoinsToAcquire.tr}:",
                style: const TextStyle(fontSize: 15),
              ),
              Obx(()=> DropdownButton<AppProduct>(
                items: _.appCoinProducts.map((AppProduct product) {
                  return DropdownMenuItem<AppProduct>(
                    value: product,
                    child: Text(product.qty.toString()),
                  );
                }).toList(),
                onChanged: (AppProduct? newProduct) {
                  _.changeAppCoinProduct(newProduct!);
                },
                value: _.appCoinProduct.value,
                alignment: Alignment.center,
                icon: const Icon(Icons.arrow_downward),
                iconSize: 20,
                elevation: 16,
                style: const TextStyle(color: Colors.white),
                dropdownColor: AppColor.main75,
                underline: Container(
                  height: 1,
                  color: Colors.grey,
                ),
              ),),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${AppTranslationConstants.paymentCurrency.tr}: ",
                style: const TextStyle(fontSize: 15),
              ),
              Obx(()=> DropdownButton<String>(
                items: AppCurrency.values.getRange(0, 1).map((AppCurrency currency) {
                  return DropdownMenuItem<String>(
                    value: currency.name,
                    child: Text(currency.name.toUpperCase()),
                  );
                }).where((currency) => currency.value != AppCurrency.appCoin.name)
                    .toList(),
                onChanged: (String? paymentCurrencyStr) {
                  _.changePaymentCurrency(newCurrency:
                  EnumToString.fromString(AppCurrency.values, paymentCurrencyStr ?? AppCurrency.mxn.name)
                      ?? AppCurrency.mxn
                  );
                },
                value: _.paymentCurrency.value.name,
                alignment: Alignment.center,
                icon: const Icon(Icons.arrow_downward),
                iconSize: 20,
                elevation: 16,
                style: const TextStyle(color: Colors.white),
                dropdownColor: AppColor.main75,
                underline: Container(
                  height: 1,
                  color: Colors.grey,
                ),
              ),
              ),
            ],
          ),
          Obx(()=> Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${AppTranslationConstants.totalToPay.tr.capitalizeFirst}:",
                style: const TextStyle(fontSize: 15),
              ),
              Row(
                children: [
                  Text("${CoreUtilities.getCurrencySymbol(_.paymentCurrency.value)} ${_.paymentAmount.value}",
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
          ),
        ],
      ),
      buttons: [
        DialogButton(
          color: AppColor.bondiBlue75,
          onPressed: () async {
            if(!_.isButtonDisabled.value) {
              await _.payAppProduct(context);
            }
          },
          child: Obx(()=> _.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : Text(AppTranslationConstants.proceedToOrder.tr,
            style: const TextStyle(fontSize: 15),
          ),
          ),
        ),
      ]
  ).show();
}