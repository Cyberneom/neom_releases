import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
// ignore: implementation_imports
import 'package:in_app_purchase_android/src/types/google_play_purchase_details.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:neom_commons/core/domain/model/subscription_plan.dart';
import 'package:neom_commons/core/utils/enums/product_type.dart';
import 'package:neom_commons/neom_commons.dart';

import '../../../data/firestore/order_firestore.dart';
import '../../../data/firestore/sales_firestore.dart';
import '../../../domain/models/app_product.dart';
import '../../../domain/models/app_sale.dart';
import '../../../domain/models/payment.dart';
import '../../../domain/models/app_order.dart';
import '../../../utils/constants/app_commerce_constants.dart';
import '../../../utils/enums/payment_status.dart';
import 'in_app_payment_queue_delegate.dart';

class OrderConfirmationController extends GetxController with GetTickerProviderStateMixin {
  
  final userController = Get.find<UserController>();

  bool isLoading = true;
  bool isButtonDisabled = false;

  AppProfile profile = AppProfile();
  ProfileType  profileType = ProfileType.general;

  final Rx<PaymentStatus> paymentStatus = PaymentStatus.pending.obs;

  AppProduct product = AppProduct();
  SubscriptionPlan subscriptionPlan = SubscriptionPlan();
  // Event event = Event();
  // Booking booking = Booking();
  // AppReleaseItem releaseItem = AppReleaseItem();

  AppCoupon? coupon;
  Payment payment = Payment();

  double discountAmount = 0.0;
  double discountPercentage = 0.0;

  AppOrder order = AppOrder();

  AppSale sales = AppSale();

  // String displayedName = "";
  // String displayedDescription = "";
  // String displayedImgUrl = "";

  final InAppPurchase inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<dynamic> _subscription;
  List<ProductDetails> inAppProducts = [];

  String inAppProductId = "";
  bool isConsumable = false;
  bool isAppPurchaseLoading = false;

  String fromRoute = '';

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.d("OrderConfirmation Controller Init");

    try {

      profile = userController.user.profiles.first;
      payment.from = userController.user.email;

      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        if(Get.arguments[0] is AppProduct) {
          product = Get.arguments[0];
          order.customerEmail = userController.user.email;
          order.description = product.name;
          order.product = product;
          payment.to = product.ownerEmail ?? '';

          switch(product.type) {
            case ProductType.event:
              AppCommerceConstants.eventCoverLevels.forEach((key, value) {
                if(product.salePrice!.amount == value) {
                  inAppProductId = key;
                }
              });
              break;
            case ProductType.appCoin:
              isConsumable = true;
              inAppProductId = product.id;
              break;
            default:
              inAppProductId = product.id;
              break;
          }

          ///DEPRECATED
          // if(product.type == ProductType.event) {
          //   AppCommerceConstants.eventCoverLevels.forEach((key, value) {
          //     if(product.salePrice!.amount == value) {
          //       inAppProductId = key;
          //     }
          //   });
          // } else {
          //   inAppProductId = product.id;
          // }
          //
          // if(product.type == ProductType.appCoin) isConsumable = true;

        } else if(Get.arguments[0] is SubscriptionPlan) {
          subscriptionPlan = Get.arguments[0];
          product = AppProduct.fromSubscriptionPlan(subscriptionPlan);

          order.customerEmail = userController.user.email;
          order.description = subscriptionPlan.name.tr;
          order.product = product;
          order.subscriptionPlan = subscriptionPlan;

          inAppProductId = subscriptionPlan.id;
        }

        if(Get.arguments.length > 1 && Get.arguments[1] is String) {
          fromRoute = Get.arguments[1];
        }

        if(Get.arguments.length > 2 && Get.arguments[2] is ProfileType) {
          profileType = Get.arguments[2];
          order.customerType = profileType;
        }

      }
    } catch (e) {
      AppUtilities.logger.i(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    try {

      DateTime now = DateTime.now();
      order.createdTime = now.millisecondsSinceEpoch;

      if(product.id.isNotEmpty) {
        ///DEPRECATED
        // displayedName = product.name;
        // displayedDescription = product.description;
        // displayedImgUrl = product.imgUrl;

        payment.price = Price(
          amount: product.salePrice?.amount ?? 0,
          currency: product.salePrice?.currency ?? AppCurrency.appCoin
        );

        sales = await SalesFirestore().retrieveSales(product.type);
        sales.orderNumber = sales.orderNumber + 1;

        order.id = "${userController.user.id.substring(0,4).toUpperCase()}"
            "${product.id.substring(0,3).toUpperCase()}"
            "${profile.name.substring(0,3).toUpperCase()}"
            "${sales.orderNumber.toString()}";

        payment.tax = product.salePrice!.amount * AppPaymentConstants.mexicanTaxesAmount;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    await initInAppPurchase();
    isLoading = false;
    update([AppPageIdConstants.orderConfirmation]);
  }

  @override
  void dispose() async {
    super.dispose();
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition = inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(null);
    }
    await _subscription.cancel();
  }

  Future<void> confirmOrder({BuildContext? context}) async {
    AppUtilities.logger.i("Order was confirmed and would be created");
    // isLoading = true;
    String orderId = "";
    update([AppPageIdConstants.orderConfirmation]);
    try {
      orderId = await OrderFirestore().insert(order);
      if(orderId.isNotEmpty && order.product != null) {
        AppUtilities.logger.d("Order was created with orderId $orderId");
        if(order.product?.type == ProductType.subscription) {
          Get.toNamed(AppRouteConstants.stripeWebView, arguments: [order, fromRoute, context]);
        } else {
          payment.orderId = order.id;
          Get.toNamed(AppRouteConstants.paymentGateway, arguments: [payment, order]);
        }
        SalesFirestore().updateOrderNumber(sales.orderNumber, order.product!.type);
        SalesFirestore().addOrderId(orderId: order.id, productType: order.product!.type);
      } else {
        Get.snackbar(
          MessageTranslationConstants.errorCreatingOrder.tr,
          MessageTranslationConstants.errorCreatingOrderMsg.tr,
          snackPosition: SnackPosition.bottom,);
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  Future<void> inAppPurchasePayment() async {
    AppUtilities.logger.d("InAppPurchase Payment for productId $inAppProductId");
    try {
      if(inAppProducts.isNotEmpty) {
        ProductDetails productDetails = inAppProducts.firstWhere((element) => element.id == inAppProductId);
        final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
        bool inAppPaymentSuccess = false;
        isAppPurchaseLoading = true;
        if(isConsumable) {
          inAppPaymentSuccess = await inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
        } else {
          inAppPaymentSuccess = await inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
        }

        if(inAppPaymentSuccess) {

        }
      }
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

    isAppPurchaseLoading = false;
    update([AppPageIdConstants.orderConfirmation]);
  }

  Future<void> initInAppPurchase() async {
    final Stream purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) async {
      await _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () async {
      await _subscription.cancel();
    }, onError: (error) {
      AppUtilities.logger.e(error.toString());
    });

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition = inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(InAppPaymentQueueDelegate());
    }

    final bool available = await InAppPurchase.instance.isAvailable();
    if(available) {
      Set<String> kIds = <String>{inAppProductId};
      final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails(kIds);
      if (response.notFoundIDs.isNotEmpty) {
        AppUtilities.logger.i("The following Product Ids were not found: ${response.notFoundIDs.toString()}");
      }
      inAppProducts = response.productDetails;
    } else {
      AppUtilities.logger.i("The InAppPurchase Store could not be reached or accessed");
    }
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // _showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {

          if(Platform.isAndroid && purchaseDetails is GooglePlayPurchaseDetails) {
            order.googlePlayPurchaseDetails = purchaseDetails;
          } else if(Platform.isIOS && purchaseDetails is AppStorePurchaseDetails){
            order.appStorePurchaseDetails = purchaseDetails;
          }

          payment.status = PaymentStatus.completed;
          await confirmOrder();
        } else if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.error) {
          AppUtilities.showSnackBar(title: AppTranslationConstants.inAppPurchase,
              message: purchaseDetails.status.toString(), duration: const Duration(seconds: 5));
          AppUtilities.logger.e(purchaseDetails.status.toString());
          // _handleError(purchaseDetails.error!);
        }
      }
    }
  }


}
