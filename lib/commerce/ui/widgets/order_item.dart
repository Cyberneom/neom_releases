import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:neom_commons/core/utils/enums/product_type.dart';
import 'package:neom_commons/neom_commons.dart';
import '../../domain/models/purchase_order.dart';


class OrderItem extends StatelessWidget {
  final PurchaseOrder order;
  const OrderItem({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {

    Widget leadingImg = const SizedBox.shrink();

    if(order.product?.type == ProductType.coin) {
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

String getAmountToDisplay(PurchaseOrder order) {
  double amount = 0;
  amount = order.product?.salePrice?.amount ?? 0;

  ///DEPRECATED
  // switch(order.saleType) {
  //   case SaleType.product:
  //     amount = order.product!.salePrice!.amount;
  //     break;
  //   case SaleType.event:
  //     amount = order.event!.coverPrice!.amount;
  //     break;
  //   case SaleType.booking:
  //     break;
  //   case SaleType.digitalItem:
  //     amount = order.releaseItem!.digitalPrice!.amount;
  //     break;
  //   case SaleType.physicalItem:
  //     amount = order.releaseItem!.physicalPrice!.amount;
  //     break;
  // }
  
  return amount.toString();
}

String getCurrencyToDisplay(PurchaseOrder order) {

  AppCurrency currency = AppCurrency.appCoin;
  currency = order.product!.salePrice!.currency;

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
