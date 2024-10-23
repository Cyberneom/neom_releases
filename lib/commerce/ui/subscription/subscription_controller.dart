import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/price.dart';
import 'package:neom_commons/core/domain/model/subscription_plan.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:neom_commons/core/utils/enums/product_type.dart';
import 'package:neom_commons/core/utils/enums/subscription_level.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:enum_to_string/enum_to_string.dart';

import '../../data/firestore/commerce_jobs_firestore.dart';
import '../../data/firestore/product_firestore.dart';
import '../../data/firestore/subscription_plan_firestore.dart';
import '../../data/stripe_service.dart';
import '../../domain/models/app_product.dart';
import '../../domain/models/stripe_price.dart';
import '../../domain/models/stripe_product.dart';

class SubscriptionController extends GetxController with GetTickerProviderStateMixin {

  final userController = Get.find<UserController>();

  RxBool isLoading = true.obs;
  Rx<SubscriptionLevel> selectedLevel = SubscriptionLevel.basic.obs;
  Rx<Price> selectedPrice = Price().obs;
  SubscriptionPlan selectedPlan = SubscriptionPlan();
  Map<String, SubscriptionPlan> subscriptionPlans = {};

  @override
  void onInit() async {
    // Map<String, List<StripePrice>> recurringPrices = await StripeService.getRecurringPricesFromStripe();
    subscriptionPlans = await SubscriptionPlanFirestore().getAll();
    if(subscriptionPlans.isNotEmpty) selectedPlan = subscriptionPlans.values.first;
    // CommerceJobsFirestore().insertSubscriptionPlans();


  }

  @override
  void onReady() async {
    update([AppPageIdConstants.accountSettings]);
  }

  Future<bool?> getSubscriptionAlert(BuildContext context, String fromRoute) async {
    AppUtilities.logger.d("getSubscriptionAlert");
    // selectedPrice.value = AppFlavour.getSubscriptionPrice();

    return Alert(
        context: context,
        style: AlertStyle(
            backgroundColor: AppColor.main50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            titleTextAlign: TextAlign.justify
        ),
        content: Obx(() => Column(
          children: <Widget>[
            AppTheme.heightSpace20,
            Text((selectedLevel.value.name + 'Msg').tr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),textAlign: TextAlign.justify,),
            AppTheme.heightSpace20,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${AppTranslationConstants.subscription.tr}: ",
                  style: const TextStyle(fontSize: 15),
                ),
                DropdownButton<String>(
                  items: subscriptionPlans.keys.map((String planName) {
                    return DropdownMenuItem<String>(
                      value: planName,
                      child: Text(planName.tr),
                    );
                  }).toList(),
                  onChanged: (String? plan) {
                    if(plan != null) {
                      changeSubscriptionPlan(plan);
                    }
                  },
                  value: selectedPlan.name,
                  alignment: Alignment.center,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 20,
                  elevation: 16,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: AppColor.getMain(),
                  underline: Container(
                    height: 1,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            AppTheme.heightSpace20,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${AppTranslationConstants.totalToPay.tr.capitalizeFirst}:",
                  style: const TextStyle(fontSize: 15),
                ),
                Row(
                  children: [
                    Text("${CoreUtilities.getCurrencySymbol(selectedPrice.value.currency)} ${selectedPrice.value.amount} ${selectedPrice.value.currency.name.tr.toUpperCase()}",
                      style: const TextStyle(fontSize: 15),
                    ),
                    AppTheme.widthSpace5,
                  ],
                ),
              ],
            ),
          ],),
        ),
        buttons: [
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () async {
              await paySubscription(fromRoute, selectedLevel.value);

            },
            child: Text(AppTranslationConstants.confirmAndProceed.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ]
    ).show();
  }

  Future<void> paySubscription(String fromRoute, SubscriptionLevel subscriptionLevel) async {
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

  void changeSubscriptionPlan(String itemType) {
    selectedLevel.value = EnumToString.fromString(SubscriptionLevel.values, itemType) ?? SubscriptionLevel.basic;
    switch(selectedLevel) {
      default:
    }
    update([AppPageIdConstants.accountSettings]);
  }



}
