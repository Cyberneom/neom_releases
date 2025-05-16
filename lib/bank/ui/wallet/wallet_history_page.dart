import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
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
import 'wallet_card.dart';
import 'wallet_controller.dart';

class WalletHistoryPage extends StatelessWidget {
  const WalletHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isAble = false;
    return GetBuilder<WalletController>(
      id: AppPageIdConstants.walletHistory,
      init: WalletController(),
      builder: (_) => Scaffold(
        appBar:  PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: AppBarChild(title: AppTranslationConstants.wallet.tr)
        ),
        backgroundColor: AppColor.main50,
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          height: AppTheme.fullHeight(context),
          child: _.isLoading.value ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTheme.heightSpace20,
                Padding(padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: WalletCard(),
                ),
                AppTheme.heightSpace20,
                // Padding(
                //   padding: const EdgeInsets.all(16.0),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       Text.rich(
                //         TextSpan(
                //           children: [
                //             TextSpan(
                //               text: '${AppTranslationConstants.currentAmount.tr} \n',
                //               style: Theme.of(context)
                //                   .textTheme.titleLarge!
                //                   .copyWith(
                //                   color: Colors.grey,
                //                   fontSize: 16),
                //             ),
                //             TextSpan(
                //               text: '${AppFlavour.getAppCoinName()}: ${_.wallet.amount.truncate().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                //               style: Theme.of(context)
                //                   .textTheme.titleLarge!
                //                   .copyWith(
                //                   fontWeight: FontWeight.bold,
                //                   fontSize: 25,
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //       if(isAble) IconButton(
                //         iconSize: 40,
                //         icon: const CircleAvatar(
                //           radius: 30,
                //           backgroundColor: AppColor.yellow,
                //           child: Icon(
                //             Icons.add,
                //             color: Colors.black38,
                //             size: 40,
                //           ),
                //         ),
                //         onPressed: () {
                //           showGetAppcoinsAlert(context, _);
                //         },
                //       ),
                //     ],
                //   ),
                // ),
                Divider(thickness: 1, color: AppColor.white80),
                SizedBox(
                  width: AppTheme.fullWidth(context),
                  child: Text(
                    AppTranslationConstants.transactionsHistory.tr,
                    style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Divider(thickness: 1, color: AppColor.white80),
                SizedBox(
                  height: AppTheme.fullHeight(context)*0.7,
                  child: _.orders.isNotEmpty ? buildOrderList(context, _)
                      :  buildNoHistoryToShow(context, _),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
              if(!_.isButtonDisabled) {
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
}
