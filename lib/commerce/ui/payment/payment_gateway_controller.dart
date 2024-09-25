import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/countries.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/bank_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/firestore/user_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/address.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/app_user.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/intl_countries_list.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:neom_commons/core/utils/enums/product_type.dart';
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
import '../../utils/constants/payment_gateway_constants.dart';
import '../../utils/enums/payment_status.dart';
import '../wallet/wallet_controller.dart';



class PaymentGatewayController extends GetxController with GetTickerProviderStateMixin implements PaymentGatewayService {
  
  final userController = Get.find<UserController>();

  final TextEditingController _emailController = TextEditingController();
  TextEditingController get emailController => _emailController;

  TextEditingController phoneController = TextEditingController();

  final Rx<Country> phoneCountry = IntlPhoneConstants.availableCountries.first.obs;
  final RxBool isButtonDisabled = false.obs;
  final RxBool isLoading = true.obs;

  String userId = '';
  AppProfile profile = AppProfile();

  final Rx<PaymentStatus> paymentStatus = PaymentStatus.pending.obs;
  final RxBool showWalletAmount = false.obs;  

  String errorMsg = "";
  String phoneNumber = '';
  
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
    AppUtilities.logger.d("Payment Gateway Controller Init");

    try {
      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        if (Get.arguments[0] is Payment) {
          payment = Get.arguments[0];
        }

        if (Get.arguments[1] != null && Get.arguments[1] is PurchaseOrder) {
          order = Get.arguments[1];
        }
      }

      userId = userController.user.id;
      profile = userController.user.profiles.first;
      emailController.text = userController.user.email;
      phoneController.text = userController.user.phoneNumber;

      stripe.Stripe.publishableKey = AppFlavour.getStripePublishableKey();
      await stripe.Stripe.instance.applySettings();

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();

    try {
      String paymentId = await PaymentFirestore().insert(payment);
      payment.id = paymentId;

      ///DEPRECATED NOT TO REGISTER ORDER UNTIL PAYMENT IS INTENDED
      // if(await UserFirestore().addOrderId(userId: userId, orderId: payment.orderId)) {
      //   userController.user.orderIds.add(payment.orderId);
      // } else {
      //   AppUtilities.logger.w("Something occurred while adding order to User $userId");
      // }

      if(payment.price?.currency == AppCurrency.appCoin) {
        update([AppPageIdConstants.paymentGateway]);
        AppUtilities.logger.d('Paying with AppCoins');
        await payWithAppCoins();
      } else if(payment.status == PaymentStatus.completed &&
          (order.googlePlayPurchaseDetails != null || order.appStorePurchaseDetails != null)) {
        AppUtilities.logger.d('Payment was already Completed through GooglePlay or AppStore');
        paymentStatus.value = payment.status;
        await handleProcessedPayment();
      } else {
        AppUtilities.logger.d('Paying through Stripe');
        isLoading.value = false;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
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
    AppUtilities.logger.d("Starting handlePayment Process");

    try {

      paymentStatus.value = PaymentStatus.processing;
      errorMsg = Validator.validateEmail(emailController.text);

      if(errorMsg.isEmpty) {
        if (phoneController.text.isEmpty ||
            (phoneController.text.length < phoneCountry.value.minLength
                || phoneController.text.length > phoneCountry.value.maxLength)
        ) {
          errorMsg = MessageTranslationConstants.pleaseEnterPhone;
          phoneNumber = "";
        } else if (phoneCountry.value.code.isEmpty) {
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
        isLoading.value = true;
        isButtonDisabled.value = true;
        update([AppPageIdConstants.paymentGateway, AppPageIdConstants.eventDetails]);

        stripe.BillingDetails billingDetails = stripe.BillingDetails(
          name: userController.user.name,
          email: emailController.text,
          phone: phoneNumber,
          address: stripe.Address(
            city: profile.address.isNotEmpty ? profile.address.split(',').first : '',
            country: phoneCountry.value.name,
            line1: '',
            line2: '',
            state: '',
            postalCode: '',
          ),
        );

        if(userController.user.userRole == UserRole.superAdmin) {
          paymentStatus.value = PaymentStatus.completed;
        } else {
          await handlePaymentMethod(billingDetails);
        }

        await PaymentFirestore().updatePaymentStatus(payment.id, paymentStatus.value);

        if(paymentStatus.value == PaymentStatus.completed) {
          await handleProcessedPayment();
        } else {
          isButtonDisabled.value = false;
          isLoading.value = false;
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
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.paymentGateway, AppPageIdConstants.eventDetails]);
  }


  @override
  Future<void> payWithAppCoins() async {
    AppUtilities.logger.d("Entering payWithGigCoins Method");

    paymentStatus.value = PaymentStatus.processing;

    try {
      ///Validate and get coins from user wallet
      if((payment.price != null) && (userController.user.wallet.amount >= (payment.price?.amount ?? 0))) {
        if(Validator.isEmail(payment.to)) {
          ///Add coins to host wallet
          await payToUserWithCoins();
        } else {
          ///Add coins to bank in case there is no payment.to
          await payToBank();
        }
      } else {
        paymentStatus.value = PaymentStatus.failed;
        errorMsg = MessageTranslationConstants.notEnoughFundsMsg.tr;
        AppUtilities.logger.i(MessageTranslationConstants.notEnoughFundsMsg.tr);
      }

      await PaymentFirestore().updatePaymentStatus(payment.id, paymentStatus.value);

      if(paymentStatus.value == PaymentStatus.completed) {
        await handleProcessedPayment();
      } else {
        Get.back();
        AppUtilities.showSnackBar(
          title: MessageTranslationConstants.errorProcessingPayment.tr,
          message: errorMsg.tr,
        );
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.paymentGateway]);
  }

  Future<void> payToUserWithCoins() async {
    ///Add coins to host wallet
    AppUser? toUser = await UserFirestore().getByEmail(payment.to);
    if(toUser != null && toUser.id.isNotEmpty) {
      if(await UserFirestore().addToWallet(toUser.id, payment.price!.amount)) {
        ///Remove coins from user wallet
        if(await UserFirestore().subtractFromWallet(userId, payment.price!.amount)) {
          userController.subtractFromWallet(payment.price!.amount);
          paymentStatus.value = PaymentStatus.completed;
        } else {
          paymentStatus.value = PaymentStatus.rolledBack;
          if(await UserFirestore().subtractFromWallet(toUser.id, payment.price!.amount)) {
            AppUtilities.logger.i("Amount ${payment.price!.amount} rolledback from wallet successfully for profile ${payment.to}");
          } else {
            AppUtilities.logger.i("Something happened subtracting from wallet for profile ${payment.to}");
          }
        }
      } else {
        paymentStatus.value = PaymentStatus.failed;
        AppUtilities.logger.w("Something happened: ${MessageTranslationConstants.errorProcessingPaymentMsg.tr}");
        Get.snackbar(
            MessageTranslationConstants.errorProcessingPayment.tr,
            MessageTranslationConstants.errorProcessingPaymentMsg.tr,
            snackPosition: SnackPosition.bottom);
      }
    }
  }

  Future<void> payToBank() async {
    ///Add coins to bank
    if(await BankFirestore().addAmount(payment.from, payment.price!.amount, payment.orderId, reason: 'ProductPurchase')) {
      ///Remove coins from user wallet
      if(await ProfileFirestore().subtractFromWallet(payment.from, payment.price!.amount)) {
        paymentStatus.value = PaymentStatus.completed;
        userController.subtractFromWallet(payment.price!.amount);
      } else {
        paymentStatus.value = PaymentStatus.rolledBack;
        if(await BankFirestore().subtractAmount(payment.from, payment.price!.amount, orderId: payment.orderId, reason: 'Rollback')) {
          AppUtilities.logger.i("Amount ${payment.price!.amount} rolledback from wallet successfully for profile ${payment.to}");
        } else {
          AppUtilities.logger.i("Something happened subtracting from wallet for profile ${payment.to}");
        }
      }
    } else {
      paymentStatus.value = PaymentStatus.failed;
      AppUtilities.logger.w("Something happened: ${MessageTranslationConstants.errorProcessingPaymentMsg.tr}");
      Get.snackbar(
          MessageTranslationConstants.errorProcessingPayment.tr,
          MessageTranslationConstants.errorProcessingPaymentMsg.tr,
          snackPosition: SnackPosition.bottom);
    }
  }


  @override
  Future<void> handleProcessedPayment() async {

    try {
      if(paymentStatus.value == PaymentStatus.completed) {

        await generateAndInsertInvoice();

        if(await UserFirestore().addOrderId(userId: userId, orderId: payment.orderId)) {
          userController.user.orderIds.add(payment.orderId);
        } else {
          AppUtilities.logger.w("Something occurred while adding order to User $userId");
        }

        switch(order.product?.type) {
          case ProductType.event:
            EventDetailsController eventDetailsController;

            if (Get.isRegistered<EventDetailsController>()) {
              eventDetailsController = Get.find<EventDetailsController>();
            } else {
              eventDetailsController = EventDetailsController();
              Get.put(eventDetailsController);
              await eventDetailsController.getEvent(order.product!.id);
            }
            await eventDetailsController.goingToEvent();

            Get.toNamed(AppRouteConstants.splashScreen,
                arguments: [AppRouteConstants.paymentGateway, AppRouteConstants.home]);
            break;
          case ProductType.appCoin:
            int coinsQty = 0;

            try {
              coinsQty = Get.find<WalletController>().appCoinProduct.value.qty;
              AppUtilities.logger.d('$coinsQty from found WalletController');
            } catch(e) {
              coinsQty = Get.put(WalletController()).appCoinProduct.value.qty;
              AppUtilities.logger.d('$coinsQty from initiated WalletController');
            }

            if(await UserFirestore().addToWallet(userId, coinsQty.toDouble())) {
              userController.addToWallet(coinsQty);
            }

            Get.toNamed(AppRouteConstants.splashScreen,
                arguments: [AppRouteConstants.paymentGateway, AppRouteConstants.wallet]);
            break;
          case ProductType.digital:
          case ProductType.physical:
            if(await UserFirestore().addBoughtItem(userId: userId, itemId: order.product?.id ?? "")) {
              userController.user.boughtItems ??= [];
              userController.user.boughtItems!.add(order.product!.id);
            }

            AppReleaseItemFirestore().addBoughtUser(releaseItemId: order.product!.id, userId: userId);
            Get.toNamed(AppRouteConstants.splashScreen,
                arguments: [AppRouteConstants.paymentGateway,
                  AppRouteConstants.lists]);
            break;
          case ProductType.subscription:
          // TODO: Handle this case.
          // CHANGE USER TO PREMIUM
          case ProductType.service:
          case ProductType.external:
          case ProductType.booking:
          case ProductType.crowdfunding:
          case ProductType.notDefined:
          default:
            break;

        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  Future<void> generateAndInsertInvoice() async {
    Invoice invoice = Invoice(
      description: order.description,
      orderId: payment.orderId,
      createdTime: DateTime.now().millisecondsSinceEpoch,
      payment: payment,
    );

    invoice.toUser = userController.user;
    invoice.id = await InvoiceFirestore().insert(invoice);

    if(invoice.id.isNotEmpty) {
      await OrderFirestore().addInvoiceId(orderId: payment.orderId, invoiceId: invoice.id);
    }
  }


  @override
  Future<void> handlePaymentMethod(stripe.BillingDetails billingDetails) async {

    stripe.PaymentMethod paymentMethod;
    Map<String, dynamic> paymentIntentResponse;

    try {
        // 1. Create payment method providing billingDetails
        paymentMethod = await stripe.Stripe.instance.createPaymentMethod(
            params: stripe.PaymentMethodParams.card(
                paymentMethodData: stripe.PaymentMethodData(
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

          stripe.PaymentIntent paymentIntent = await stripe.Stripe.instance.confirmPayment(
              paymentIntentClientSecret: paymentIntentResponse[PaymentGatewayConstants.clientSecret],
              data: stripe.PaymentMethodParams.cardFromMethodId(
                paymentMethodData: stripe.PaymentMethodDataCardFromMethod(
                    paymentMethodId: paymentMethod.id
                ),
              )
          );

          if (paymentIntentResponse[PaymentGatewayConstants.requiresAction] == true) {
            // 3. if payment requires action calling handleCardAction
            AppUtilities.logger.w("Payment requires an action...");
            paymentIntent = await stripe.Stripe.instance
              .handleNextAction(paymentIntent.clientSecret);
            //TODO handle error
            //if (cardActionError) {} else

            if (paymentIntent.status == stripe.PaymentIntentsStatus.RequiresConfirmation) {
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

    } on stripe.StripeException catch (e) {
      errorMsg = e.error.localizedMessage ?? "";
      paymentStatus.value = PaymentStatus.declined;
      AppUtilities.logger.e(errorMsg);
    } catch (e) {
      paymentStatus.value = PaymentStatus.unknown;
      AppUtilities.logger.e(e.toString());
    }

  }

  @override
  Future<void> handleSuscriptionPayment(stripe.BillingDetails billingDetails) async {

    stripe.PaymentMethod paymentMethod;
    Map<String, dynamic> paymentIntentResponse;

    try {
      // 1. Create payment method providing billingDetails
      paymentMethod = await stripe.Stripe.instance.createPaymentMethod(
          params: stripe.PaymentMethodParams.card(
              paymentMethodData: stripe.PaymentMethodData(
                  billingDetails: billingDetails
              )
          )
      );

      AppUtilities.logger.i("Valid payment method added successfully");
      AppUtilities.logger.i(paymentMethod.toString());

      final String apiUrl = 'https://api.stripe.com/v1/subscriptions';
      // Crear el cliente en Stripe
      final customerResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/customers'),
        headers: {
          'Authorization': 'Bearer ${AppFlavour.getStripeSecretLiveKey()}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': userController.user.email,
          'payment_method': paymentMethod.id,
          'invoice_settings[default_payment_method]': paymentMethod.id,
        },
      );


      final customer = json.decode(customerResponse.body);
      final customerId = customer['id'];

      // Crear la suscripción
      final subscriptionResponse = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer ${AppFlavour.getStripeSecretLiveKey()}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'customer': customerId,
          'items[0][price]': 'price_1PzmXjHpVUHkmiYF9Vcoau6V',
          'expand[]': 'latest_invoice.payment_intent',
        },
      );

      final subscription = json.decode(subscriptionResponse.body);
      AppUtilities.logger.i('Subscription created: ${subscription['id']}');
    } on stripe.StripeException catch (e) {
      errorMsg = e.error.localizedMessage ?? "";
      paymentStatus.value = PaymentStatus.declined;
      AppUtilities.logger.e(errorMsg);
    } catch (e) {
      paymentStatus.value = PaymentStatus.unknown;
      AppUtilities.logger.e(e.toString());
    }

  }

  @override
  Future<Map<String, dynamic>> createPaymentIntent(
      String amount, String currency) async {
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
