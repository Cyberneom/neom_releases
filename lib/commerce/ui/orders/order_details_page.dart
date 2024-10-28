import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/app_circular_progress_indicator.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/read_more_container.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:neom_commons/core/utils/enums/product_type.dart';
import '../../utils/commerce_utilities.dart';
import 'order_details_controller.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderDetailsController>(
      id: AppPageIdConstants.orderDetails,
      init: OrderDetailsController(),
      builder: (_) => Scaffold(
        appBar: AppBarChild(title: AppTranslationConstants.orderDetails.tr),
        backgroundColor: AppColor.main50,
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          padding: const EdgeInsets.all(20),
          height: AppTheme.fullHeight(context),
          child: _.isLoading ? const AppCircularProgressIndicator() : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                 Container(
                   decoration: AppTheme.appBoxDecorationBlueGrey,
                   padding: const EdgeInsets.all(10),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: <Widget>[
                       SizedBox(
                         width: AppTheme.fullWidth(context)/4,
                         height: AppTheme.fullWidth(context)/4,
                         child: _.order.product?.type == ProductType.appCoin
                             ? Image.asset(AppAssets.appCoins13)
                             : Image.network(_.product?.imgUrl.isNotEmpty ?? false ? _.product!.imgUrl
                             : AppFlavour.getNoImageUrl()
                         ),
                       ),
                       SizedBox(
                        width: AppTheme.fullWidth(context)*0.5,
                        height: AppTheme.fullWidth(context)/4,
                        child: Column(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: <Widget>[
                               Text(_.order.product?.type.name.tr ?? '',
                                 style: const TextStyle(
                                     fontSize: 15,
                                     fontWeight: FontWeight.bold
                                 ),
                                 overflow: TextOverflow.ellipsis,
                                 maxLines: 1,
                               ),
                               AppTheme.heightSpace5,
                               Text(_.displayedName.tr,
                                   style: const TextStyle(
                                       fontSize: 12
                                   ),
                                   overflow: TextOverflow.ellipsis,
                                   maxLines: 1
                               ),
                               AppTheme.heightSpace5,
                             SizedBox(
                               width: AppTheme.fullWidth(context)/2,
                               child: Text(_.displayedDescription.tr,
                                   style: const TextStyle(
                                       fontSize: 12,
                                   ),
                                   textAlign: TextAlign.justify,
                                   overflow: TextOverflow.ellipsis,
                                   maxLines: 2
                               ),
                             ),
                             AppTheme.heightSpace10,
                             _.product?.reviewIds?.isNotEmpty ?? false ? Row(
                                 children: <Widget>[
                                   Container(
                                       margin: const EdgeInsets.only(right: 5),
                                       child: const Icon(Icons.star,color: Colors.yellow, size: 15)),
                                   Container(
                                     margin: const EdgeInsets.only(right: 5),
                                     child: Align(
                                       alignment: Alignment.topLeft,
                                       child:  Text("${_.product!.reviewStars.toString()} (${_.product!.reviewIds?.length.toString()})",
                                           style: const TextStyle(
                                               fontSize: 12,
                                               fontWeight: FontWeight.bold
                                           ),
                                           overflow: TextOverflow.ellipsis),
                                     ),
                                   ),
                                 ],
                               ) : const SizedBox.shrink(),
                           ],
                         ),
                      ),
                     ],
                   ),
                 ),
                AppTheme.heightSpace10,
                _.order.url.isNotEmpty ? Column(children: [
                  Divider(color: AppColor.white80),
                  TextButton(
                    onPressed: () => CoreUtilities.launchURL(_.order.url),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0), // Removes any minimum size constraints
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduces the tap area to the content
                    ),
                    child: Text(AppTranslationConstants.checkInvoice.tr),
                  )
                ],) : const SizedBox.shrink(),
                Divider(color: AppColor.white80),
                Text(AppTranslationConstants.yourPurchase.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
                ),
                AppTheme.heightSpace10,
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
                AppTheme.heightSpace10,
                Text(AppTranslationConstants.paymentDetails.tr,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18)
                ),
                AppTheme.heightSpace5,
                Text(_.payment.status.name.tr,
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16),
                ),
                AppTheme.heightSpace10,
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
                AppTheme.heightSpace10,
                Text(AppTranslationConstants.orderDetails.tr,
                   style: const TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 18)
                ),
                AppTheme.heightSpace5,
                SizedBox(
                  height: AppTheme.fullHeight(context)/6,
                  child: SingleChildScrollView(
                    child: ReadMoreContainer(text: "${_.order.description.tr}${_.order.product!.description.isNotEmpty ? "\n${_.order.product!.description.tr}" : ""}",
                      padding: 0,
                      trimLines: 6,
                      color: Colors.grey,
                    ),
                  ),
                ),
                AppTheme.heightSpace10,
                Text(AppTranslationConstants.priceDetails.tr,
                   style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 17)
                ),
                AppTheme.heightSpace5,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    SizedBox(
                      width: AppTheme.fullWidth(context)/2,
                      child: Text(_.displayedName.tr,
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                          ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text("${_.product?.regularPrice?.amount} ${_.product?.regularPrice?.currency.name.tr.toUpperCase()}",
                       style: const TextStyle(
                           color: Colors.grey,
                           fontSize: 16)
                    ),
                  ],
                ),
                AppTheme.heightSpace10,
                _.payment.price?.amount == 0.0 || _.discountPercentage == 0 ? const SizedBox.shrink() :
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("${AppTranslationConstants.discount.tr} (${CommerceUtilities.getFormattedDiscountPercentage(_.discountPercentage)}%)",
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16
                        )
                    ),
                    Text("${((_.product?.regularPrice?.amount ?? 0) - (_.payment.price?.amount ?? 0))} ${_.payment.price?.currency.name.tr.toUpperCase() ?? AppCurrency.mxn.name.toUpperCase()}",
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
                    Text("${_.payment.price?.amount ?? 0} ${_.payment.price?.currency.name.tr.toUpperCase() ??  AppCurrency.mxn.name.toUpperCase()}",
                        style: TextStyle(
                            color: AppColor.white80,
                            fontSize: 16)
                    ),
                  ],
                ),
                AppTheme.heightSpace20
           ]
          ),
        ),
      ),
    );
  }

}
