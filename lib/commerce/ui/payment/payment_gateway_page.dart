import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'payment_gateway_controller.dart';


class PaymentGatewayPage extends StatelessWidget {

  const PaymentGatewayPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PaymentGatewayController>(
      id: AppPageIdConstants.paymentGateway,
      init: PaymentGatewayController(),
      builder: (_) => Scaffold(
        appBar: AppBarChild(),
        body: SingleChildScrollView(
          controller: ScrollController(initialScrollOffset: 100),
          child: Container(
            padding: const EdgeInsets.all(30),
            height: AppTheme.fullHeight(context),
            decoration: AppTheme.appBoxDecoration,
            child: Flex(
              direction: Axis.vertical,
              children: [
                Expanded(
                child: Obx(()=> _.isLoading ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                          labelText: 'Email'),
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
                        backgroundColor: Platform.isIOS ? AppColor.white : AppColor.getMain(),
                      ),
                    ),
                    AppTheme.heightSpace10,
                    Column(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: AppTheme.fullWidth(context) * 0.5,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: AppColor.bondiBlue75,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                              ),
                              onPressed: () async => _.isButtonDisabled ? {} : _.handleStripePayment(),
                              child: Text("${AppTranslationConstants.toPay.tr} ${CoreUtilities.getCurrencySymbol(_.payment.price.currency)}"
                                  "${_.payment.finalAmount} (${_.payment.price.currency.name.toUpperCase()})",
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white
                                ),
                              ),
                            ),
                          ),
                        ),
                        _.cardEditController.details.complete ? Container()
                        : Column(
                          children: [
                            AppTheme.heightSpace10,
                            Text(MessageTranslationConstants.pleaseFillCardInfo.tr,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red
                              ),
                            ),
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
      initialCountryCode: Get.locale!.countryCode,
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
