import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:neom_commons/core/utils/enums/sale_type.dart';
import '../../domain/models/purchase_order.dart';


class OrderItem extends StatelessWidget {
  final PurchaseOrder order;
  const OrderItem({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: ListTile(
        leading: order.saleType == SaleType.product ? Image.asset(AppAssets.appCoin, height: 40) :
        order.saleType == SaleType.event ? Image.network(order.event!.imgUrl) : Container(),
        title: Text(
          order.description,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18
          )
        ),
        subtitle: Text(AppUtilities.dateFormat(order.createdTime),
          style: const TextStyle(fontSize: 15),
        ),
        trailing: Text("${getAmountToDisplay(order)} ${getCurrencyToDisplay(order).toUpperCase()}",
            style: const TextStyle(
                color: AppColor.white,
                fontSize: 18)
        ),
        onTap: () => Get.toNamed(AppRouteConstants.orderDetails, arguments: [order]),
      ),
    );
  }
}

String getAmountToDisplay(PurchaseOrder order) {
  double amount = 0;
  switch(order.saleType) {
    case SaleType.product:
      amount = order.product!.salePrice!.amount;
      break;
    case SaleType.event:
      amount = order.event!.coverPrice!.amount;
      break;
    case SaleType.booking:      
      break;      
  }
  
  return amount.toString();
}

String getCurrencyToDisplay(PurchaseOrder order) {

  AppCurrency currency = AppCurrency.appCoin;
  switch(order.saleType) {
    case SaleType.product:
      currency = order.product!.salePrice!.currency;
      break;
    case SaleType.event:
      currency = order.event!.coverPrice!.currency;
      break;
    case SaleType.booking:
      break;
  }

  return currency.name;
}
