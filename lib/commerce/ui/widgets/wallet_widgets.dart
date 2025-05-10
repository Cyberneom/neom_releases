import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import '../../domain/models/transaction_order.dart';
import '../wallet/wallet_controller.dart';
import 'order_item.dart';

Widget buildOrderList(BuildContext context, WalletController _){
  return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
      itemCount: _.orders.length,
      itemBuilder: (context, index) {
        TransactionOrder order = _.orders.values.elementAt(index);
        return OrderItem(order: order);
      }
  );

}

Widget buildNoHistoryToShow(BuildContext context, WalletController _){
  return Padding(
    padding: const EdgeInsets.only(left: 15, right: 15),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[        
        Text(
          AppTranslationConstants.appCoinComingSoon.tr,
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        AppTheme.heightSpace20,
        Image.asset(AppAssets.appCoin, height: 150),
        AppTheme.heightSpace20,
        Text(
          AppTranslationConstants.noHistoryToShow.tr,
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ],
    ),
  );
}
