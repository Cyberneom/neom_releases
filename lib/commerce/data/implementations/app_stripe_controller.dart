import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';

import '../../domain/models/payment.dart';
import '../../utils/constants/payment_gateway_constants.dart';
import '../../utils/enums/payment_status.dart';

class AppStripeController {

  static final AppStripeController _instance = AppStripeController._internal();
  factory AppStripeController() {
    _instance._init();
    return _instance;
  }

  AppStripeController._internal();

  bool _isInitialized = false;
  String errorMsg = "";
  final Rx<PaymentStatus> paymentStatus = PaymentStatus.pending.obs;

  // If you are using a real device to test the integration replace this url
  // with the endpoint of your test server (it usually should be the IP of your computer)
  String kApiUrl = Platform.isAndroid ? 'http://10.0.2.2:4242' : 'http://localhost:4242';

  /// Inicialización manual para controlar mejor el ciclo de vida
  Future<void> _init() async {
    AppUtilities.logger.t('AppStripeController Initialization');

    if (_isInitialized) return;
    _isInitialized = true;

    try {
      Stripe.publishableKey = AppFlavour.getStripePublishableKey();
      await Stripe.instance.applySettings();
      AppUtilities.logger.t('Stripe publishable key: ${AppFlavour.getStripePublishableKey()}');
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  Future<void> handlePayment() async {


  }

  @override
  Future<void> handlePaymentMethod(Payment payment, BillingDetails billingDetails) async {

    PaymentMethod paymentMethod;
    Map<String, dynamic> paymentIntentResponse;

    try {
      // 1. Create payment method providing billingDetails
      paymentMethod = await Stripe.instance.createPaymentMethod(
          params: PaymentMethodParams.card(
              paymentMethodData: PaymentMethodData(
                  billingDetails: billingDetails
              )
          )
      );

      AppUtilities.logger.i("Valid payment method added successfully");
      AppUtilities.logger.i(paymentMethod.toString());

      // 2. call API to create PaymentIntent
      int amountToPayInCents = (payment.price!.amount * 100).toInt();
      paymentIntentResponse = await createPaymentIntent(
          amountToPayInCents.toString(),
          payment.price!.currency.name
      );

      if (paymentIntentResponse[PaymentGatewayConstants.clientSecret] != null && paymentMethod.id.isNotEmpty) {
        AppUtilities.logger.i("Payment intent created successfully");

        PaymentIntent paymentIntent = await Stripe.instance.confirmPayment(
            paymentIntentClientSecret: paymentIntentResponse[PaymentGatewayConstants.clientSecret],
            data: PaymentMethodParams.cardFromMethodId(
              paymentMethodData: PaymentMethodDataCardFromMethod(
                  paymentMethodId: paymentMethod.id
              ),
            )
        );

        if (paymentIntentResponse[PaymentGatewayConstants.requiresAction] == true) {
          // 3. if payment requires action calling handleCardAction
          AppUtilities.logger.w("Payment requires an action...");
          paymentIntent = await Stripe.instance
              .handleNextAction(paymentIntent.clientSecret);
          //TODO handle error
          //if (cardActionError) {} else

          if (paymentIntent.status == PaymentIntentsStatus.RequiresConfirmation) {
            // 4. Call API to confirm intent
            AppUtilities.logger.w("Payment Intent requires confirmation");
            await confirmIntent(paymentIntent.id);
          } else {
            // Payment succedeed
            errorMsg = 'Error: ${paymentIntentResponse[PaymentGatewayConstants.error]} - I believe there is no error here';
          }
        } else if(paymentIntentResponse[PaymentGatewayConstants.requiresAction] == null) {
          // Payment succedeed
          AppUtilities.logger.i("Payment Intent and Confirmation were created successfully");
          paymentStatus.value = PaymentStatus.completed;
        }
      }

      if (paymentIntentResponse[PaymentGatewayConstants.error] != null) {
        // Error during creating or confirming Intent
        paymentStatus.value = PaymentStatus.failed;
        errorMsg = 'Error: ${paymentIntentResponse[PaymentGatewayConstants.error]}';
      }

    } on StripeException catch (e) {
      errorMsg = e.error.localizedMessage ?? "";
      paymentStatus.value = PaymentStatus.declined;
      AppUtilities.logger.e(errorMsg);
    } catch (e) {
      paymentStatus.value = PaymentStatus.unknown;
      AppUtilities.logger.e(e.toString());
    }

  }

  @override
  Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency) async {
    AppUtilities.logger.d("Creating payment intent with amount: $amount and currency: $currency");

    try {
      Map<String, String> body = {
        PaymentGatewayConstants.amount: amount,
        PaymentGatewayConstants.currency: currency,
        '${PaymentGatewayConstants.paymentMethodTypes}[]': PaymentGatewayConstants.card
      };

      final response = await http.post(
          Uri.parse('${AppFlavour.getPaymentGatewayBaseURL()}/payment_intents'),
          body: body,
          headers: {
            'Authorization': 'Bearer ${AppFlavour.getStripeSecretLiveKey()}',
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          encoding: Encoding.getByName("utf-8"));

      // Check if the response is successful
      if (response.statusCode == 200) {
        AppUtilities.logger.d('Stripe API Post Request successfully created: ${response.statusCode} - ${response.body}');
        return jsonDecode(response.body);
      } else {
        AppUtilities.logger.e('Stripe API error: ${response.statusCode} - ${response.body}');
      }

    } catch (err) {
      AppUtilities.logger.e('error in stripe create payment intent:${err.toString()}');
    }
    return {};
  }

  @override
  Future<void> confirmIntent(String paymentIntentId) async {
    AppUtilities.logger.d("Confirming payment intent with id: $paymentIntentId");

    final result = await callNoWebhookPayEndpointIntentId(
        paymentIntentId: paymentIntentId);
    if (result['error'] != null) {
      Get.snackbar("Error", 'Error: ${result['error']}');
    } else {
      Get.snackbar("Success", 'Success!: The payment was confirmed successfully!');
    }
  }

  @override
  Future<Map<String, dynamic>> callNoWebhookPayEndpointIntentId({required String paymentIntentId,}) async {
    AppUtilities.logger.d("Calling no webhook pay endpoint with paymentIntentId: $paymentIntentId");

    try {
      final url = Uri.parse('$kApiUrl/charge-card-off-session');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'paymentIntentId': paymentIntentId}),
      );

      return json.decode(response.body);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return {};
  }

}
