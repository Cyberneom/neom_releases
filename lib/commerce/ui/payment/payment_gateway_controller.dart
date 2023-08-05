import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/countries.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/firestore/user_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/address.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:neom_commons/core/utils/enums/user_role.dart';
import 'package:neom_commons/core/utils/validator.dart';
import 'package:neom_events/events/ui/event_details_controller.dart';

import '../../data/firestore/invoice_firestore.dart';
import '../../data/firestore/order_firestore.dart';
import '../../data/firestore/payment_firestore.dart';
import '../../domain/models/invoice.dart';
import '../../domain/models/payment.dart';
import '../../domain/models/purchase_order.dart';
import '../../domain/use_cases/payment_gateway_service.dart';
import '../../utils/enums/payment_status.dart';
import '../../utils/enums/payment_type.dart';
import '../wallet_controller.dart';



class PaymentGatewayController extends GetxController with GetTickerProviderStateMixin implements PaymentGatewayService {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  final TextEditingController _emailController = TextEditingController();
  TextEditingController get emailController => _emailController;

  TextEditingController phoneController = TextEditingController();

  final Rx<Country> _phoneCountry = countries[0].obs;
  Country get phoneCountry => _phoneCountry.value;
  set phoneCountry(Country country) => _phoneCountry.value = country;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  AppProfile profile = AppProfile();

  final Rx<PaymentStatus> _paymentStatus = PaymentStatus.pending.obs;
  PaymentStatus get paymentStatus => _paymentStatus.value;
  set paymentStatus(PaymentStatus paymentStatus) => _paymentStatus.value = paymentStatus;

  final Rx<PaymentType> _paymentType = PaymentType.notDefined.obs;
  PaymentType get paymentType => _paymentType.value;
  set paymentType(PaymentType paymentType) => _paymentType.value = paymentType;

  final RxBool _showWalletAmount = false.obs;
  bool get showWalletAmount => _showWalletAmount.value;
  set showWalletAmount(bool showWalletAmount) => _showWalletAmount.value = showWalletAmount;

  String errorMsg = "";
  String phoneNumber = '';
  String apiBase = 'https://api.stripe.com/v1';
  // If you are using a real device to test the integration replace this url
  // with the endpoint of your test server (it usually should be the IP of your computer)
  String kApiUrl = Platform.isAndroid ? 'http://10.0.2.2:4242' : 'http://localhost:4242';

  stripe.CardFieldInputDetails? cardFieldInputDetails;
  stripe.CardFormEditController cardEditController = stripe.CardFormEditController();

  PurchaseOrder order = PurchaseOrder();
  Payment payment = Payment();
  Address userAddress = Address();

  @override
  void onInit() async {
    super.onInit();
    logger.d("Payment Gateway Controller Init");

    try {
      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        if (Get.arguments[0] is Payment) {
          payment = Get.arguments[0];
        }

        if (Get.arguments[1] != null && Get.arguments[1] is PurchaseOrder) {
          order = Get.arguments[1];
        }
      }

      profile = userController.user!.profiles.first;
      emailController.text = userController.user?.email ?? "";
      phoneController.text = userController.user?.phoneNumber ?? "";

      for (var country in countries) {
        if(Get.locale!.countryCode == country.code){
          phoneCountry = country; //Mexico
        }
      }
    } catch (e) {
      logger.i(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();

    try {
      String paymentId = await PaymentFirestore().insert(payment);

      if(paymentId.isNotEmpty) {
        payment.id = paymentId;
        OrderFirestore().addPaymentId(orderId: payment.orderId, paymentId: payment.id);
      }

      if(payment.price.currency == AppCurrency.appCoin) {
        update([AppPageIdConstants.paymentGateway]);
        await payWithAppCoins();
      } else if(payment.status == PaymentStatus.completed
          && (order.googlePlayPurchaseDetails != null || order.appStorePurchaseDetails != null)) {
        paymentStatus = payment.status;
        await handleProcessedPayment();
      } else {
        isLoading = false;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.paymentGateway]);
  }

  @override
  void onClose() {
    cardEditController.removeListener(update);
    cardEditController.dispose();
  }

  @override
  Future<void> handleStripePayment() async {
    logger.d("Starting handlePayment Process");

    try {

      paymentStatus = PaymentStatus.processing;
      errorMsg = Validator.validateEmail(emailController.text);

      if(errorMsg.isEmpty) {
        if (phoneController.text.isEmpty ||
            (phoneController.text.length < phoneCountry.minLength
                || phoneController.text.length > phoneCountry.maxLength)
        ) {
          errorMsg = MessageTranslationConstants.pleaseEnterPhone;
          phoneNumber = "";
        } else if (phoneCountry.code.isEmpty) {
          errorMsg = MessageTranslationConstants.pleaseEnterCountryCode;
          phoneNumber = "";
        } else {
          phoneNumber = phoneController.text;
        }
      }

      if(!cardEditController.details.complete) {
        errorMsg = MessageTranslationConstants.pleaseFillCardInfo;
      }

      if(errorMsg.isEmpty) {
        isLoading = true;
        isButtonDisabled = true;
        update([AppPageIdConstants.paymentGateway, AppPageIdConstants.eventDetails]);

        stripe.BillingDetails billingDetails = stripe.BillingDetails(
          name: userController.user?.name ?? "",
          email: emailController.text,
          phone: phoneNumber,
          address: stripe.Address(
            city: '',
            country: phoneCountry.name,
            line1: '',
            line2: '',
            state: '',
            postalCode: '',
          ),
        );

        if(userController.user!.userRole == UserRole.superAdmin) {
          paymentStatus = PaymentStatus.completed;
        } else {
          await handlePaymentMethod(billingDetails);
        }

        await PaymentFirestore().updatePaymentStatus(payment.id, paymentStatus);

        if(errorMsg.isEmpty) {
          await handleProcessedPayment();
        } else {
          isButtonDisabled = false;
          isLoading = false;
          Get.snackbar(
            MessageTranslationConstants.errorCapturingPayment.tr,
            errorMsg.tr,
            snackPosition: SnackPosition.bottom,
          );
        }
      } else {
        Get.snackbar(
          MessageTranslationConstants.errorCapturingPayment.tr,
          errorMsg.tr,
          snackPosition: SnackPosition.bottom,
        );
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.paymentGateway, AppPageIdConstants.eventDetails]);
  }


  @override
  Future<void> payWithAppCoins() async {
    logger.d("Entering payWithGigCoins Method");

    paymentStatus = PaymentStatus.processing;

    try {
      ///Validate and get coins from user wallet
      if(userController.user!.wallet.amount >= payment.price.amount) {
        ///Add coins to host wallet
        if(await ProfileFirestore().addToWallet(
            payment.to,
            payment.price.amount)) {
          ///Remove coins from user wallet
          if(await ProfileFirestore().subtractFromWallet(payment.from, payment.price.amount)) {
            paymentStatus = PaymentStatus.completed;
            userController.subtractFromWallet(payment.price.amount);
          } else {
            paymentStatus = PaymentStatus.rolledBack;
            if(await ProfileFirestore().subtractFromWallet(payment.to, payment.price.amount)) {
              logger.i("Amount ${payment.price.amount} rolledback from wallet successfully for profile ${payment.to}");
            } else {
              logger.i("Something happened subtracting from wallet for profile ${payment.to}");
            }
          }
        } else {
          paymentStatus = PaymentStatus.failed;
          logger.w("Something happened: ${MessageTranslationConstants.errorProcessingPaymentMsg.tr}");
          Get.snackbar(
              MessageTranslationConstants.errorProcessingPayment.tr,
              MessageTranslationConstants.errorProcessingPaymentMsg.tr,
              snackPosition: SnackPosition.bottom);
        }
      } else {
        paymentStatus = PaymentStatus.failed;
        errorMsg = MessageTranslationConstants.notEnoughFundsMsg.tr;
        logger.i(MessageTranslationConstants.notEnoughFundsMsg.tr);
      }

      await PaymentFirestore().updatePaymentStatus(payment.id, paymentStatus);

      if(errorMsg.isEmpty) {
        await handleProcessedPayment();
      } else {
        Get.back();
        Get.snackbar(
          MessageTranslationConstants.errorProcessingPayment.tr,
          errorMsg.tr,
          snackPosition: SnackPosition.bottom,
        );
      }

    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.paymentGateway]);
  }


  @override
  Future<void> handleProcessedPayment() async {

    try {
      if(paymentStatus == PaymentStatus.completed) {
        Invoice invoice = Invoice(
          description: order.description,
          orderId: payment.orderId,
          createdTime: DateTime.now().millisecondsSinceEpoch,
          payment: payment,
        );
        invoice.toUser = userController.user!;

        invoice.id = await InvoiceFirestore().insert(invoice);

        if(invoice.id.isNotEmpty) {
          await OrderFirestore().addInvoiceId(orderId: payment.orderId, invoiceId: invoice.id);
        }

        if(await UserFirestore().addOrderId(userId: userController.user!.id, orderId: payment.orderId)) {
          userController.user!.orderIds.add(payment.orderId);
        } else {
          logger.w("Something occurred while adding order to User ${userController.user!.id}");
        }

        switch(payment.type) {
          case PaymentType.event:
            final eventDetailsController = Get.find<EventDetailsController>();
            await eventDetailsController.goingToEvent();
            Get.toNamed(AppRouteConstants.splashScreen,
                arguments: [AppRouteConstants.paymentGateway,
                  AppRouteConstants.home]);
            break;
          case PaymentType.product:
            int coinsQty = 0;
            try {
              coinsQty = Get.find<WalletController>().appCoinProduct.qty;
            } catch(e) {
              coinsQty = Get.put(WalletController()).appCoinProduct.qty;
            }

            if(await ProfileFirestore().addToWallet(
                payment.from, coinsQty.toDouble())) {
              userController.addToWallet(coinsQty);
            }
            Get.toNamed(AppRouteConstants.splashScreen,
                arguments: [AppRouteConstants.paymentGateway,
                  AppRouteConstants.wallet]);
            break;
          case PaymentType.booking:
            break;
          case PaymentType.contribution:
            break;
          case PaymentType.sponsor:
            break;
          case PaymentType.tip:
            break;
          case PaymentType.notDefined:
            break;
          case PaymentType.releaseItem:
            if(await ProfileFirestore().addBoughtItem(userId: userController.user!.id, boughtItem: order.releaseItem?.id ?? "")) {
              userController.user!.boughtItems ??= [];
              userController.user!.boughtItems!.add(order.releaseItem!.id);
            }

            AppReleaseItemFirestore().addBoughtUser(releaseItemId: order.releaseItem!.id, userId: userController.user!.id);
            Get.toNamed(AppRouteConstants.splashScreen,
                arguments: [AppRouteConstants.paymentGateway,
                  AppRouteConstants.lists]);
            break;
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }


  @override
  Future<void> handlePaymentMethod(stripe.BillingDetails billingDetails) async {

    stripe.PaymentMethod paymentMethod;
    Map<String, dynamic> paymentIntentResponse;

    try {

        stripe.Stripe.publishableKey = AppFlavour.getStripePublishableKey();
        // 1. Create payment method providing billingDetails
        paymentMethod = await stripe.Stripe.instance.createPaymentMethod(
            params: stripe.PaymentMethodParams.card(
                paymentMethodData: stripe.PaymentMethodData(
                    billingDetails: billingDetails
                )
            )
        );

        logger.i("Valid payment method added successfully");
        logger.i(paymentMethod.toString());

        // 2. call API to create PaymentIntent
        int amountToPayInCents = (payment.price.amount * 100).toInt();
        paymentIntentResponse = await createPaymentIntent(
            amountToPayInCents.toString(),
            payment.price.currency.name
        );

        if (paymentIntentResponse['client_secret'] != null
            && paymentMethod.id.isNotEmpty
        ) {
          logger.i("Payment intent created successfully");

          stripe.PaymentIntent paymentIntent = await stripe.Stripe.instance.confirmPayment(
              paymentIntentClientSecret: paymentIntentResponse['client_secret'],
              data: stripe.PaymentMethodParams.cardFromMethodId(
                paymentMethodData: stripe.PaymentMethodDataCardFromMethod(
                    paymentMethodId: paymentMethod.id
                ),
              )
          );

          if (paymentIntentResponse['requires_action'] == true) {
            // 3. if payment requires action calling handleCardAction
            logger.w("Payment requires an action...");
            paymentIntent = await stripe.Stripe.instance
              .handleNextAction(paymentIntent.clientSecret);
            //TODO handle error
            //if (cardActionError) {} else

            if (paymentIntent.status == stripe.PaymentIntentsStatus.RequiresConfirmation) {
              // 4. Call API to confirm intent
              logger.w("Payment Intent requires confirmation");
              await confirmIntent(paymentIntent.id);
            } else {
              // Payment succedeed
              errorMsg = 'Error: ${paymentIntentResponse['error']} - Emma -> I believe we dont have an error here';
            }
          } else if(paymentIntentResponse['requires_action'] == null) {
            // Payment succedeed
            logger.i("Payment Intent and Confirmation were created successfully");
            paymentStatus = PaymentStatus.completed;
          }
        }

        if (paymentIntentResponse['error'] != null) {
          // Error during creating or confirming Intent
          paymentStatus = PaymentStatus.failed;
          errorMsg = 'Error: ${paymentIntentResponse['error']}';
        }

    } on stripe.StripeException catch (e) {
      errorMsg = e.error.localizedMessage ?? "";
      paymentStatus = PaymentStatus.declined;
      logger.e(errorMsg);
    } catch (e) {
      paymentStatus = PaymentStatus.unknown;
      logger.e(e.toString());
    }

  }

  @override
  Future<Map<String, dynamic>> createPaymentIntent(
      String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
        'payment_method_types[]': 'card'
      };
      final response = await http.post(
          Uri.parse('$apiBase/payment_intents'),
          body: body,
          headers: {
            'Authorization': 'Bearer ${AppFlavour.getStripeSecretLiveKey()}',
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          encoding: Encoding.getByName("utf-8"));
      return jsonDecode(response.body);
    } catch (err) {
      AppUtilities.logger.e('error in stripe create payment intent:${err.toString()}');
    }
    return {};
  }


  @override
  Future<void> confirmIntent(String paymentIntentId) async {
    final result = await callNoWebhookPayEndpointIntentId(
        paymentIntentId: paymentIntentId);
    if (result['error'] != null) {
      Get.snackbar("Error", 'Error: ${result['error']}');
    } else {
      Get.snackbar("Success", 'Success!: The payment was confirmed successfully!');
    }
  }

  @override
  Future<Map<String, dynamic>> callNoWebhookPayEndpointIntentId({
    required String paymentIntentId,
  }) async {
    final url = Uri.parse('$kApiUrl/charge-card-off-session');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({'paymentIntentId': paymentIntentId}),
    );
    return json.decode(response.body);
  }

}
