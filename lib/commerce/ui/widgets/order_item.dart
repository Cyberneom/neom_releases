import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/utils/enums/product_type.dart';
import 'package:neom_commons/neom_commons.dart';
import '../../domain/models/transaction_order.dart';


class OrderItem extends StatelessWidget {
  final TransactionOrder order;
  const OrderItem({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {

    Widget leadingImg = const SizedBox.shrink();

    if(order.product?.type == ProductType.appCoin) {
      leadingImg = Image.asset(AppAssets.appCoin, height: 40);
    } else {
      leadingImg  = Image.network(order.product?.imgUrl.isNotEmpty ?? false ?  order.product!.imgUrl : AppFlavour.getNoImageUrl());
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: ListTile(
        leading: leadingImg,
        title: Text(
          order.description,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(AppUtilities.dateFormat(order.createdTime),
          style: const TextStyle(fontSize: 15),
        ),
        trailing: Text("${getAmountToDisplay(order)} ${getCurrencyToDisplay(order).tr.toUpperCase()}",
            style: const TextStyle(
                color: AppColor.white,
                fontSize: 18)
        ),
        onTap: () => Get.toNamed(AppRouteConstants.orderDetails, arguments: [order]),
      ),
    );
  }
}

String getAmountToDisplay(TransactionOrder order) {
  double amount = 0;
  amount = order.product?.salePrice?.amount ?? 0;

  // Check if the amount is an integer
  if (amount.floor() == amount) {
    return amount.toInt().toString(); // Convert to integer and format
  } else {
    return amount.toStringAsFixed(1); // Format with two decimal places
  }

}

String getCurrencyToDisplay(TransactionOrder order) {

  AppCurrency currency = AppCurrency.appCoin;
  currency = order.product!.salePrice!.currency;

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
