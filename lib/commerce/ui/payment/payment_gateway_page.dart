import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/submit_button.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'payment_gateway_controller.dart';


class PaymentGatewayPage extends StatelessWidget {

  const PaymentGatewayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PaymentGatewayController>(
      id: AppPageIdConstants.paymentGateway,
      init: PaymentGatewayController(),
      builder: (_) => Scaffold(
        appBar: AppBarChild(title: AppTranslationConstants.paymentDetails.tr),
        body: SingleChildScrollView(
          controller: ScrollController(initialScrollOffset: 100),
          child: Container(
            padding: const EdgeInsets.all(20),
            height: AppTheme.fullHeight(context),
            decoration: AppTheme.appBoxDecoration,
            child: Flex(
              direction: Axis.vertical,
              children: [
                Expanded(
                child: Obx(()=> _.isLoading ? const Center(child: CircularProgressIndicator())
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("${AppTranslationConstants.toPay.tr} ${CoreUtilities.getCurrencySymbol(_.payment.price.currency)}"
                        "${_.payment.finalAmount} (${_.payment.price.currency.name.toUpperCase()}) ${AppTranslationConstants.using.tr}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
                    ),
                    AppTheme.heightSpace10,
                    TextFormField(
                      controller: _.emailController,
                      decoration: InputDecoration(
                          hintText: AppTranslationConstants.enterEmail.tr,
                          labelText: AppTranslationConstants.email.tr),
                      onChanged: (value) {
                        //emailController.text;
                      },
                    ),
                    buildPhoneField(paymentGatewayController: _),
                    AppTheme.heightSpace20,
                    CardFormField(
                      controller: _.cardEditController,
                      onCardChanged: (card) {
                        _.cardFieldInputDetails = card;
                      },
                      style: CardFormStyle(
                        placeholderColor: (Platform.isIOS && AppFlavour.appInUse == AppInUse.g) ? Colors.black : AppColor.white,
                        textColor: (Platform.isIOS && AppFlavour.appInUse == AppInUse.g) ? Colors.black : AppColor.white,
                        backgroundColor: (Platform.isIOS && AppFlavour.appInUse == AppInUse.g) ? AppColor.white : AppColor.main25,
                      ),
                      countryCode: Get.locale!.countryCode,
                      enablePostalCode: false,
                    ),
                    AppTheme.heightSpace10,
                    Column(
                      children: [
                        SubmitButton(context, isEnabled: !_.isButtonDisabled, isLoading: _.isLoading,
                        text: "${AppTranslationConstants.toPay.tr} ${CoreUtilities.getCurrencySymbol(_.payment.price.currency)}"
                            "${_.payment.finalAmount} (${_.payment.price.currency.name.toUpperCase()})",
                        onPressed: _.handleStripePayment,),
                        _.cardEditController.details.complete ? const SizedBox.shrink()
                        : Column(
                          children: [
                            AppTheme.heightSpace10,
                            Center(child: Text(MessageTranslationConstants.pleaseFillCardInfo.tr,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red
                              ),
                            ),),
                          ],
                        ),
                      ],
                    ),
                  ],),
                  )
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildPhoneField({required PaymentGatewayController paymentGatewayController}) {
  return IntlPhoneField(
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: AppTranslationConstants.phoneNumber.tr,
        alignLabelWithHint: true,
      ),
      pickerDialogStyle: PickerDialogStyle(
          backgroundColor: AppColor.getMain(),
          searchFieldInputDecoration: InputDecoration(
            labelText: AppTranslationConstants.searchByCountryName.tr,
          ),
      ),
      initialValue: paymentGatewayController.phoneController.text,
      initialCountryCode: "MX",
      onChanged: (phone) {
        paymentGatewayController.phoneController.text = phone.number;
      },
      onCountryChanged: (country) {
        paymentGatewayController.phoneCountry = country;
      },
      //TODO Verify if invalidNumberMessage is needed
      invalidNumberMessage: ""

  );
}
