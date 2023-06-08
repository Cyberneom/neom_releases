import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/sale_type.dart';
import 'order_confirmation_controller.dart';

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderConfirmationController>(
      id: AppPageIdConstants.orderConfirmation,
      init: OrderConfirmationController(),
      builder: (_) => Scaffold(
        appBar: AppBarChild(title: AppTranslationConstants.confirmOrder.tr),
        body:  SingleChildScrollView(
          child: Container(
            decoration: AppTheme.appBoxDecoration,
            padding: const EdgeInsets.all(20),
            height: AppTheme.fullHeight(context),
            child: Obx(()=> _.isLoading ? const Center(child: CircularProgressIndicator()) : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                   Container(
                     decoration: AppTheme.appBoxDecorationBlueGrey,
                     padding: const EdgeInsets.all(10),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                       children: <Widget>[
                         SizedBox(
                          height: 100,
                          width: 100,
                          child: _.order.saleType == SaleType.product
                              ? Image.asset(AppAssets.appCoins13)
                              : Image.network(_.displayedImgUrl.isNotEmpty ? _.displayedImgUrl
                              : AppFlavour.getNoImageUrl()
                          ),
                         ),
                         Column(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           crossAxisAlignment: CrossAxisAlignment.center,
                           children: <Widget>[
                               Text(_.order.saleType.name.tr,
                                 style: const TextStyle(
                                     fontSize: 15,
                                     fontWeight: FontWeight.bold
                                 ),
                                 overflow: TextOverflow.ellipsis,
                                 maxLines: 1,
                               ),
                               AppTheme.heightSpace10,
                               Text(_.displayedName,
                                   style: const TextStyle(
                                       fontSize: 12
                                   ),
                                   overflow: TextOverflow.ellipsis,
                                   maxLines: 1
                               ),
                               AppTheme.heightSpace10,
                               SizedBox(
                                 width: 120,
                                 child:
                                   Text(_.displayedDescription,
                                     style: const TextStyle(
                                         fontSize: 12
                                     ),
                                     overflow: TextOverflow.ellipsis,
                                     maxLines: 2
                                 ),
                               ),
                               AppTheme.heightSpace10,
                             _.product.reviewIds.isNotEmpty ? Row(
                                 children: <Widget>[
                                   Container(
                                       margin: const EdgeInsets.only(right: 5),
                                       child: const Icon(Icons.star,color: Colors.yellow, size: 15)),
                                   Container(
                                     margin: const EdgeInsets.only(right: 5),
                                     child: Align(
                                       alignment: Alignment.topLeft,
                                       child:  Text("${_.product.reviewStars.toString()} (${_.product.reviewIds.length.toString()})",
                                           style: const TextStyle(
                                               fontSize: 12,
                                               fontWeight: FontWeight.bold
                                           ),
                                           overflow: TextOverflow.ellipsis),
                                     ),
                                   ),
                                 ],
                               ) : Container(),
                           ],
                         ),
                       ],
                     ),
                   ),
                  AppTheme.heightSpace20,
                  Divider(color: AppColor.white80),
                  Text(AppTranslationConstants.yourPurchase.tr,
                      style: const TextStyle(
                         fontWeight: FontWeight.bold,
                         fontSize: 20)
                  ),
                  AppTheme.heightSpace20,
                  Text(AppTranslationConstants.order.tr,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18)
                  ),
                  AppTheme.heightSpace5,
                  Text(_.order.id,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16),
                  ),
                  AppTheme.heightSpace20,
                  Text(AppTranslationConstants.orderDate.tr,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18)
                  ),
                  AppTheme.heightSpace5,
                  Text(AppUtilities.dateFormat(_.order.createdTime),
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16),
                  ),
                  AppTheme.heightSpace20,
                  Text(AppTranslationConstants.orderDetails.tr,
                     style: const TextStyle(
                         fontWeight: FontWeight.bold,
                         fontSize: 18)
                  ),
                  AppTheme.heightSpace5,
                  Text(_.order.description.tr,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16),
                  ),
                  AppTheme.heightSpace20,
                  Text(AppTranslationConstants.priceDetails.tr,
                     style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 17)
                  ),
                  AppTheme.heightSpace5,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(_.displayedName,
                         style: const TextStyle(
                             color: Colors.grey,
                             fontSize: 16)
                      ),
                      Text("${_.payment.price.amount} ${_.payment.price.currency.name.toUpperCase()}",
                         style: const TextStyle(
                             color: Colors.grey,
                             fontSize: 16)
                      ),
                    ],
                  ),
                  AppTheme.heightSpace10,
                   _.payment.discountAmount == 0.0 ? Container() :
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: <Widget>[
                       Text("${AppTranslationConstants.discount.tr} (${_.discountPercentage.truncate()}%)",
                           style: const TextStyle(
                               color: Colors.grey,
                               fontSize: 16
                           )
                       ),
                       Text("${_.payment.discountAmount} ${_.payment.price.currency.name.toUpperCase()}",
                           style: const TextStyle(
                               color: Colors.grey,
                               fontSize: 16)
                       ),
                     ],
                   ),
                   Divider(color: AppColor.white80),
                  AppTheme.heightSpace10,
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: <Widget>[
                       Text(AppTranslationConstants.total.tr,
                           style: TextStyle(
                               color: AppColor.white80,
                               fontSize: 16, fontWeight: FontWeight.w600)
                       ),
                       Text("${_.payment.finalAmount} ${_.payment.price.currency.name.toUpperCase()}",
                           style: TextStyle(
                               color: AppColor.white80,
                               fontSize: 16)
                       ),
                     ],
                   ),
                   AppTheme.heightSpace20,
                   Center(
                     child: SizedBox(
                       width: AppTheme.fullWidth(context) * 0.5,
                       child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: AppColor.bondiBlue75,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0)
                          ),
                        ),
                        onPressed: () async {
                          await _.confirmOrder();
                        },
                        child: Text(AppTranslationConstants.confirmOrder.tr,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center
                        )
                       ),
                     ),
                   )
             ]
            ),),
          ),
        ),
      ),
    );
  }
}
