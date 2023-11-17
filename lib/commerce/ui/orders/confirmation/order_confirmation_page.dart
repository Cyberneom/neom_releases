import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/submit_button.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/sale_type.dart';
import 'order_confirmation_controller.dart';

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({super.key});

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
            child: Obx(()=> _.isLoading ? const Center(child: CircularProgressIndicator())
                : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                   Container(
                     decoration: AppTheme.appBoxDecorationBlueGrey,
                     padding: const EdgeInsets.all(10),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.start,
                       children: <Widget>[
                         SizedBox(
                           width: AppTheme.fullWidth(context)/4,
                           height: AppTheme.fullWidth(context)/4,
                           child: ClipRRect(
                               borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                               child: _.order.saleType == SaleType.product 
                                   ? Image.asset(AppAssets.appCoins13) 
                                   : Image.network(_.displayedImgUrl.isNotEmpty ? _.displayedImgUrl 
                                   : AppFlavour.getNoImageUrl(),
                               )
                           ),
                         ),
                         AppTheme.widthSpace10,
                         SizedBox(
                           width: AppTheme.fullWidth(context)/2,
                           child: Column(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: <Widget>[
                             Text(_.order.saleType.name.tr,
                               style: const TextStyle(
                                   fontSize: 15,
                                   fontWeight: FontWeight.bold
                               ),
                             ),
                             AppTheme.heightSpace10,
                             Text(_.displayedName,
                                 style: const TextStyle(
                                     fontSize: 12
                                 ),
                                 overflow: TextOverflow.ellipsis,
                                 maxLines: 2
                             ),
                             AppTheme.heightSpace10,
                             Text(_.displayedDescription,
                                 style: const TextStyle(
                                     fontSize: 12
                                 ),
                                 overflow: TextOverflow.ellipsis,
                                 maxLines: 2
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
                         ),),
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
                  Text("${_.order.description.tr}${_.product.description.isNotEmpty ? " - ${_.product.description}" : ""}",
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
                      Text(_.displayedName.length < AppConstants.maxAppItemNameLength
                          ? _.displayedName : "${_.displayedName.substring(0, AppConstants.maxAppItemNameLength)}...",
                         style: const TextStyle(
                             color: Colors.grey,
                             fontSize: 16),
                      ),
                      Text("${_.payment.price.amount} ${_.payment.price.currency.name.tr.toUpperCase()}",
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
                       Text("${_.payment.discountAmount} ${_.payment.price.currency.name.tr.toUpperCase()}",
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
                       Text("${_.payment.finalAmount} ${_.payment.price.currency.name.tr.toUpperCase()}",
                           style: TextStyle(
                               color: AppColor.white80,
                               fontSize: 16)
                       ),
                     ],
                   ),
                   AppTheme.heightSpace20,
                  Center(
                     child: SubmitButton(context, text: AppTranslationConstants.confirmOrder.tr,
                         onPressed: () async {await _.confirmOrder();
                     }),
                  ),
                  AppFlavour.appInUse == AppInUse.c ? Center(
                    child: TextButton(
                      onPressed: () async {
                        await _.inAppPurchasePayment();
                        ///DEPRECATED
                        // showModalBottomSheet(
                        //   context: context,
                        //   builder: (context) {
                        //     return FutureBuilder(
                        //       future: InAppPurchase.instance.queryProductDetails(<String>{_.inAppProductId}),
                        //       builder: (context, snapshot) {
                        //         if (snapshot.connectionState == ConnectionState.done) {
                        //           if (snapshot.hasError) {
                        //             return Text('Error getting products');
                        //           } else {
                        //             List<ProductDetails> products = snapshot.data?.productDetails ?? [];
                        //             return ListView(
                        //               shrinkWrap: true,
                        //               children: products
                        //                   .map((product) => ListTile(
                        //                   tileColor: AppColor.main75,
                        //                   leading: Icon(!Platform.isAndroid
                        //                       ? FontAwesomeIcons.googlePay : FontAwesomeIcons.applePay,
                        //                       size: 30),
                        //                   title: Text(product.title),
                        //                   subtitle: Text(product.description, textAlign: TextAlign.justify,),
                        //                   trailing: Text(product.price,),
                        //                   onTap: () async {
                        //                     await _.inAppPurchasePayment(product);
                        //                   }))
                        //                   .toList(),
                        //             );
                        //           }
                        //         } else {
                        //           return Center(child: CircularProgressIndicator());
                        //         }
                        //       },
                        //     );
                        //   },
                        // );
                      },
                      child: Text(Platform.isAndroid
                          ? AppTranslationConstants.payWithInAppPurchaseAndroid.tr : AppTranslationConstants.payWithInAppPurchaseIOS.tr,
                        style: const TextStyle(color: AppColor.white, decoration: TextDecoration.underline),
                      ),
                    ),
                  ) : Container()
             ]
            ),),
          ),
        ),
      ),
    );
  }
}
