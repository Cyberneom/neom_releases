import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/neom_commons.dart';
import '../../domain/models/app_transaction.dart';


class TransactionTile extends StatelessWidget {
  final AppTransaction transaction;
  const TransactionTile({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(10),
      child: ListTile(
        leading: Image.asset(AppAssets.appCoin, height: 40),
        title: Text(transaction.description,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(AppUtilities.dateFormat(transaction.createdTime),
          style: const TextStyle(fontSize: 15),
        ),
        trailing: Text('${transaction.amount} ${transaction.currency.name.tr.toUpperCase()}',
            style: const TextStyle(
                color: AppColor.white,
                fontSize: 18)
        ),
        onTap: () => Get.toNamed(AppRouteConstants.transactionDetails, arguments: [transaction]),
      ),
    );
  }
}

String getAmountToDisplay(AppTransaction transaction) {
  AppUtilities.logger.t("Transaction amount: ${transaction.amount}");

  double amount = transaction.amount;

  // Check if the amount is an integer
  if (amount.floor() == amount) {
    return amount.toInt().toString(); // Convert to integer and format
  } else {
    return amount.toStringAsFixed(1); // Format with two decimal places
  }

}

String getCurrencyToDisplay(AppTransaction transaction) {

  AppCurrency currency = AppCurrency.appCoin;
  currency = transaction.currency;

  ///DEPRECATED 090824
  // switch(order.saleType) {
  //   case SaleType.product:
  //
  //     break;
  //   case SaleType.event:
  //     currency = order.event!.coverPrice!.currency;
  //     break;
  //   case SaleType.booking:
  //     // TODO: Handle this case.
  //     break;
  //   case SaleType.digitalItem:
  //     currency = order.releaseItem!.digitalPrice!.currency;
  //     break;
  //   case SaleType.physicalItem:
  //     currency = order.releaseItem!.physicalPrice!.currency;
  //     break;
  // }

  return currency.name;
}
