import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/price.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:neom_commons/core/utils/enums/product_type.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../../data/stripe_service.dart';
import '../../domain/models/app_product.dart';

class SubscriptionController extends GetxController with GetTickerProviderStateMixin {

  final userController = Get.find<UserController>();

  RxBool isLoading = true.obs;
  final Rx<AppCurrency> currentCurrency = AppCurrency.mxn.obs;

  @override
  void onInit() async {
  }

  @override
  void onReady() async {

  }

  Future<bool?> getSubscriptionAlert(BuildContext context, String fromRoute) async {
    AppUtilities.logger.d("getSubscriptionAlert");

    return Alert(
        context: context,
        style: AlertStyle(
            backgroundColor: AppColor.main50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            titleTextAlign: TextAlign.justify
        ),
        title: AppTranslationConstants.buySubscriptionMsg.tr,
        content: Column(
          children: <Widget>[
            AppTheme.heightSpace20,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${AppTranslationConstants.totalToPay.tr.capitalizeFirst}:",
                  style: const TextStyle(fontSize: 15),
                ),
                Row(
                  children: [
                    Text("${CoreUtilities.getCurrencySymbol(currentCurrency.value)} ${AppFlavour.getSubscriptionPrice().amount} ${AppCurrency.mxn.name.tr.toUpperCase()}",
                      style: const TextStyle(fontSize: 15),
                    ),
                    AppTheme.widthSpace5,
                  ],
                ),
              ],
            ),
          ],
        ),
        buttons: [
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () async {
              await paySubscription(fromRoute);

            },
            child: Text(AppTranslationConstants.confirmAndProceed.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ]
    ).show();
  }

  Future<void> paySubscription(String fromRoute) async {
    AppUtilities.logger.d("Entering paySusbscription Method");

    try {
      AppProduct product = AppProduct(
          type: ProductType.subscription,
          salePrice: Price(
            currency: AppCurrency.mxn,
            amount: 79.0,
          ),
          id: AppFlavour.getStripeSuscriptionPriceId(),
          regularPrice: Price(
            currency: AppCurrency.mxn,
            amount: 79.0,
          ),
          description: AppTranslationConstants.subscriptionMainDesc.tr,
          name: AppTranslationConstants.subscriptionMainName.tr,
          imgUrl: 'https://www.escritoresmxi.org/wp-content/uploads/2024/09/EMXI-Lecturas-Demo.jpg'

      );

      Get.toNamed(AppRouteConstants.orderConfirmation, arguments: [product, fromRoute]);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.appItemDetails, AppPageIdConstants.bookDetails]);
  }

  Future<void> cancelSubscription() async {
    AppUtilities.logger.d("Entering paySusbscription Method");

    try {
      if(await StripeService.cancelSubscription(userController.user.subscriptionId)) {
        userController.updateSubscriptionId('');
        Get.offAllNamed(AppRouteConstants.home);
        AppUtilities.showSnackBar(
          title: 'Suscripción Cancelada Satisfactoriamente',
          message: 'Tu suscripción a EMXI Lecturas fue cancelada.'
              ' Sigue disfrutando de nuestro contenido de manera gratuita. '
              '¡Muchas gracias por utilizar EMXI',
          duration: Duration(seconds: 6),
        );
      } else {

      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.appItemDetails, AppPageIdConstants.bookDetails, AppPageIdConstants.accountSettings]);
  }

}
