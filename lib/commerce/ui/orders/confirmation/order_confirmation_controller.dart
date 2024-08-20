import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
// ignore: implementation_imports
import 'package:in_app_purchase_android/src/types/google_play_purchase_details.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:neom_commons/core/utils/enums/product_type.dart';
import 'package:neom_commons/neom_commons.dart';

import '../../../data/firestore/order_firestore.dart';
import '../../../data/firestore/sales_firestore.dart';
import '../../../domain/models/app_product.dart';
import '../../../domain/models/app_sale.dart';
import '../../../domain/models/payment.dart';
import '../../../domain/models/purchase_order.dart';
import '../../../utils/constants/app_commerce_constants.dart';
import '../../../utils/enums/payment_status.dart';
import 'in_app_payment_queue_delegate.dart';

class OrderConfirmationController extends GetxController with GetTickerProviderStateMixin {
  
  final userController = Get.find<UserController>();

  bool isLoading = true;
  bool isButtonDisabled = false;

  AppProfile profile = AppProfile();

  final Rx<PaymentStatus> paymentStatus = PaymentStatus.pending.obs;

  AppProduct product = AppProduct();
  // Event event = Event();
  // Booking booking = Booking();
  // AppReleaseItem releaseItem = AppReleaseItem();

  AppCoupon? coupon;
  Payment payment = Payment();

  double discountAmount = 0.0;
  double discountPercentage = 0.0;

  PurchaseOrder order = PurchaseOrder();

  AppSale sales = AppSale();

  String displayedName = "";
  String displayedDescription = "";
  String displayedImgUrl = "";

  final InAppPurchase inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<dynamic> _subscription;
  List<ProductDetails> inAppProducts = [];

  String inAppProductId = "";
  bool isConsumable = false;
  bool isAppPurchaseLoading = false;

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.d("OrderConfirmation Controller Init");

    try {

      profile = userController.user.profiles.first;
      payment.from = profile.id;

      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        if (Get.arguments[0] is AppProduct) {
          product = Get.arguments[0];
          order.customerEmail = userController.user.email;
          order.description = product.name;
          order.product = product;
          payment.to = product.ownerId;

          if(product.type == ProductType.event) {
            AppCommerceConstants.eventCoverLevels.forEach((key, value) {
              if(product.salePrice!.amount == value) {
                inAppProductId = key;
              }
            });
          } else {
            inAppProductId = product.id;
          }

          if(product.type == ProductType.coin) isConsumable = true;

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
        displayedName = product.name;
        displayedDescription = product.description;
        displayedImgUrl = product.imgUrl;

        payment.price?.amount = product.salePrice?.amount ?? 0;
        payment.price?.currency = product.salePrice?.currency ?? AppCurrency.appCoin;

        sales = await SalesFirestore().retrieveSales(product.type);
        sales.orderNumber = sales.orderNumber + 1;

        order.id = "${userController.user.id.substring(0,4).toUpperCase()}"
            "${product.id.substring(0,3).toUpperCase()}"
            "${profile.name.substring(0,3).toUpperCase()}"
            "${sales.orderNumber.toString()}";

        payment.tax = product.salePrice!.amount * AppPaymentConstants.mexicanTaxesAmount;
      }

      // switch(order.saleType) {
      //   case SaleType.product:
      //     if(product.id.isNotEmpty) {
      //       displayedName = product.name;
      //       displayedDescription = product.description;
      //
      //       payment.price.amount = product.regularPrice!.amount;
      //       payment.price.currency = product.regularPrice!.currency;
      //       if(product.regularPrice!.amount != product.salePrice!.amount) {
      //         payment.discountAmount = (product.regularPrice!.amount - product.salePrice!.amount).toPrecision(2);
      //         discountPercentage = ((100 * payment.discountAmount) / payment.price.amount).toPrecision(2);
      //       }
      //
      //       sales = await SalesFirestore().retrieveProductSales();
      //       sales.orderNumber = sales.orderNumber + 1;
      //
      //       order.id = "${userController.user!.id.substring(0,5).toUpperCase()}"
      //           "${product.id.substring(0,5).toUpperCase()}"
      //           "${profile.name.substring(0,3).toUpperCase()}"
      //           "${sales.orderNumber.toString()}";
      //
      //       payment.finalAmount = product.salePrice!.amount;
      //       payment.tax = product.salePrice!.amount * AppPaymentConstants.mexicanTaxesAmount;
      //
      //
      //     }
      //     break;
      //   case SaleType.event:
      //     if (event.id.isNotEmpty) {
      //       displayedName = event.name;
      //       displayedDescription = event.description;
      //       displayedImgUrl = event.imgUrl;
      //       payment.price.amount = event.coverPrice!.amount;
      //       payment.price.currency = event.coverPrice!.currency;
      //
      //       sales = await SalesFirestore().retrieveEventSales();
      //       sales.orderNumber = sales.orderNumber + 1;
      //
      //       order.id = "${userController.user!.id
      //           .substring(0,5).toUpperCase()}"
      //           "${event.id.substring(0,5).toUpperCase()}"
      //           "${profile.name.substring(0,3).toUpperCase()}"
      //           "${sales.orderNumber.toString()}";
      //
      //       payment.finalAmount = event.coverPrice!.amount;
      //       payment.tax = event.coverPrice!.amount * AppPaymentConstants.mexicanTaxesAmount;
      //     }
      //     break;
      //   case SaleType.booking:
      //     // TODO: Handle this case.
      //     break;
      //   case SaleType.digitalItem:
      //     if (releaseItem.id.isNotEmpty) {
      //       displayedName = releaseItem.name;
      //       displayedDescription = releaseItem.description;
      //       displayedImgUrl = releaseItem.imgUrl;
      //       payment.price.amount = releaseItem.digitalPrice!.amount;
      //       payment.price.currency = releaseItem.digitalPrice!.currency;
      //
      //       sales = await SalesFirestore().retrieveReleaseItemSales();
      //       sales.orderNumber = sales.orderNumber + 1;
      //
      //       order.id = "${userController.user!.id
      //           .substring(0,5).toUpperCase()}"
      //           "${releaseItem.id.substring(0,5).toUpperCase()}"
      //           "${profile.name.substring(0,3).toUpperCase()}"
      //           "${sales.orderNumber.toString()}";
      //
      //       payment.finalAmount = payment.price.amount;
      //       payment.tax = payment.finalAmount * AppPaymentConstants.mexicanTaxesAmount;
      //     }
      //     break;
      //   case SaleType.physicalItem:
      //     displayedName = releaseItem.name;
      //     displayedDescription = releaseItem.description;
      //     displayedImgUrl = releaseItem.imgUrl;
      //     payment.price.amount = releaseItem.physicalPrice!.amount;
      //     payment.price.currency = releaseItem.physicalPrice!.currency;
      //
      //     sales = await SalesFirestore().retrieveReleaseItemSales();
      //     sales.orderNumber = sales.orderNumber + 1;
      //
      //     order.id = "${userController.user!.id
      //         .substring(0,5).toUpperCase()}"
      //         "${releaseItem.id.substring(0,5).toUpperCase()}"
      //         "${profile.name.substring(0,3).toUpperCase()}"
      //         "${sales.orderNumber.toString()}";
      //
      //     payment.finalAmount = payment.price.amount;
      //     payment.tax = payment.finalAmount * AppPaymentConstants.mexicanTaxesAmount;
      //     break;
      // }

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

  Future<void> confirmOrder() async {
    AppUtilities.logger.i("Order was confirmed and would be created");
    // isLoading = true;
    String orderId = "";
    update([AppPageIdConstants.orderConfirmation]);
    try {
      orderId = await OrderFirestore().insert(order);
      if(orderId.isNotEmpty && order.product != null) {
        await SalesFirestore().updateOrderNumber(sales.orderNumber, order.product!.type);
        await SalesFirestore().addOrderId(orderId: order.id, productType: order.product!.type);
        payment.orderId = order.id;
        Get.toNamed(AppRouteConstants.paymentGateway, arguments: [payment, order]);
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
    if (available) {
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
