import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';

import 'package:neom_commons/neom_commons.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/firestore/payment_firestore.dart';
import '../../data/stripe_service.dart';
import '../../domain/models/payment.dart';
import '../../domain/models/purchase_order.dart';
import '../../domain/models/stripe_session.dart';
import '../../utils/constants/stripe_webview_constants.dart';
import '../../utils/enums/payment_status.dart';

class StripeViewController extends GetxController  {

  final userController = Get.find<UserController>();

  AppProfile profile = AppProfile();
  AppReleaseItem releaseItem = AppReleaseItem();

  WebViewController webViewController = WebViewController();
  bool isLoading = true;
  bool canPopWebView = false;

  bool clearCache = true;
  bool clearCookies = true;
  String url = '';
  String loadingSubtitle = 'Cargando plataforma de compra';

  bool isDigital = true;

  StripeCheckoutSession checkoutSession = StripeCheckoutSession();
  String customerId = '';
  String priceId = '';
  String subscriptionId = '';
  PurchaseOrder order = PurchaseOrder();

  BuildContext? context;
  String fromRoute = '';

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.i("StripeWebView Controller Init");


    if(clearCache) webViewController.clearCache();
    if(clearCookies) await CoreUtilities.clearWebViewCookies();

    try {
      profile = userController.user.profiles.first;

      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        if(Get.arguments[0] is PurchaseOrder) {
          order = Get.arguments[0];
        }

        if(Get.arguments.length > 1 && Get.arguments[1] is String) {
          fromRoute = Get.arguments[1];
        }

        if(Get.arguments.length > 2 && Get.arguments[2] is BuildContext) {
          context = Get.arguments[2];
        }



      }

      checkoutSession = await StripeService.createCheckoutSessionUrl(userController.user.email);

      webViewController.setBackgroundColor(AppColor.main50);
      Uri uri = Uri.parse(checkoutSession.url);
      webViewController.loadRequest(uri);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();

    webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    webViewController.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          isLoading = true;
          if(url.contains(StripeWebViewConstants.checkout)) {
            loadingSubtitle = 'Dirigiendo a Stripe Checkout';
          } else if(url.contains(StripeWebViewConstants.suscripcionConfirmada)) {
            loadingSubtitle = '¡Orden creada satisfactoriamente!\nDirigiendo a detalles del pedido';
          }

          update([AppPageIdConstants.stripeWebView]);
        },
        onPageFinished: (String url) async {
          try {
            isLoading = false;
            update([AppPageIdConstants.stripeWebView]);
          } catch(e) {
            AppUtilities.logger.e(e.toString());
          }

        },
        onHttpError: (HttpResponseError error) {
          AppUtilities.logger.e(error.toString());
        },
        onWebResourceError: (WebResourceError error) {
          AppUtilities.logger.e(error.toString());
        },
        onNavigationRequest: (NavigationRequest request) async {
          AppUtilities.logger.d('Navigation Request for URL: ${request.url}');
          if (request.url == url || StripeWebViewConstants.allowedUrls.any((allowedUrl) => request.url.contains(allowedUrl))) {
            canPopWebView = false;
            update([AppPageIdConstants.stripeWebView]);

            if(request.url.contains(StripeWebViewConstants.suscripcionConfirmada)) {
              createInternalPayment();
              await userController.addOrderId(order.id);

              customerId = await StripeService.getCustomerId(checkoutSession.id);
              subscriptionId = await StripeService.getSubscriptionId(checkoutSession.id);

              if(customerId.isNotEmpty) userController.updateCustomerId(customerId);
              if(subscriptionId.isNotEmpty) userController.updateSubscriptionId(subscriptionId);


              if(fromRoute.isNotEmpty) {
                switch(fromRoute) {
                  case AppRouteConstants.accountSettings:
                    Get.offAllNamed(AppRouteConstants.home);
                    break;
                  case AppRouteConstants.pdfViewer:
                    if(context != null) {
                      Navigator.pop(context!);
                      Navigator.pop(context!);
                      Navigator.pop(context!);
                    }
                    break;
                  default:
                    break;
                }
              }

              AppUtilities.showSnackBar(
                  title: 'Suscripción "EMXI Lecturas" Confirmada',
                  message: 'Ahora puedes seguir disfrutando de tus lecturas sin impedimentos. '
                      '¡Muchas gracias por aprovechar nuestra plataforma!',
                duration: Duration(seconds: 6),
              );
            } else if(request.url.contains(StripeWebViewConstants.suscripcionFallida)) {
              if(context != null) Navigator.pop(context!);
              AppUtilities.showSnackBar(
                  title: "Suscripción Fallida",
                  message: 'Algo sucedio al intentar realizar el pago de la suscripción. Favor de intentar de nuevo.'
              );
            }

            AppUtilities.logger.d('Navigating URL: ${request.url}');
            return NavigationDecision.navigate;
          } else {
            AppUtilities.logger.d('Preventing URL: ${request.url}');
            return NavigationDecision.prevent;
          }
        },
      ),
    );

    update([AppPageIdConstants.stripeWebView]);
  }

  void setCanPopWebView(bool canPop) {
    canPopWebView = canPop;
    update([AppPageIdConstants.stripeWebView]);
  }

  @override
  Future<void> createInternalPayment() async {

    if(order.id.isNotEmpty) {
      Payment payment = Payment(
          orderId: order.id,
          createdTime: DateTime.now().millisecondsSinceEpoch,
          from: userController.user.email,
          status: PaymentStatus.completed,
          price: order.product?.salePrice,
      );

      PaymentFirestore().insert(payment);
    }

  }

}
