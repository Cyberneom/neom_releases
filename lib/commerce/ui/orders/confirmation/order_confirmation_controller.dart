import 'package:get/get.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/domain/model/booking.dart';
import 'package:neom_commons/core/domain/model/event.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_payment_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/sale_type.dart';

import '../../../data/firestore/order_firestore.dart';
import '../../../data/firestore/sales_firestore.dart';
import '../../../domain/models/app_product.dart';
import '../../../domain/models/app_sale.dart';
import '../../../domain/models/payment.dart';
import '../../../domain/models/purchase_order.dart';
import '../../../utils/enums/payment_status.dart';
import '../../../utils/enums/payment_type.dart';

class OrderConfirmationController extends GetxController with GetTickerProviderStateMixin {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

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

  AppProduct product = AppProduct();
  Event event = Event();
  Booking booking = Booking();
  AppReleaseItem releaseItem = AppReleaseItem();
  
  Payment payment = Payment();
  double discountPercentage = 0.0;

  PurchaseOrder order = PurchaseOrder();

  AppSale sales = AppSale();

  String displayedName = "";
  String displayedDescription = "";
  String displayedImgUrl = "";

  @override
  void onInit() async {
    super.onInit();
    logger.d("OrderConfirmation Controller Init");

    try {

      profile = userController.user!.profiles.first;
      payment.from = profile.id;

      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        if (Get.arguments[0] is AppProduct) {
          product = Get.arguments[0];
          order.saleType = SaleType.product;
          order.description = product.name;
          order.product = product;
          payment.type = PaymentType.product;
        } else if (Get.arguments[0] is Event) {
          event = Get.arguments[0];
          order.saleType = SaleType.event;
          order.description = event.name;
          order.event = event;
          payment.type = PaymentType.event;
          payment.to = event.owner!.id;
        } else if (Get.arguments[0] is AppReleaseItem) {
          releaseItem = Get.arguments[0];
          order.saleType = SaleType.releaseItem;
          order.description = releaseItem.name;
          order.releaseItem = releaseItem;
          payment.type = PaymentType.releaseItem;
          payment.to = releaseItem.ownerId;
        }
      }

    } catch (e) {
      logger.i(e.toString());
    }

  }


  @override
  void onReady() async {
    try {

      DateTime now = DateTime.now();
      order.createdTime = now.millisecondsSinceEpoch;

      switch(order.saleType) {
        case SaleType.product:
          if(product.id.isNotEmpty) {
            displayedName = product.name;
            displayedDescription = product.description;

            payment.price.amount = product.regularPrice!.amount;
            payment.price.currency = product.regularPrice!.currency;
            if(product.regularPrice!.amount != product.salePrice!.amount) {
              payment.discountAmount = (product.regularPrice!.amount - product.salePrice!.amount).toPrecision(2);
              discountPercentage = ((100 * payment.discountAmount) / payment.price.amount).toPrecision(2);
            }

            sales = await SalesFirestore().retrieveProductSales();
            sales.orderNumber = sales.orderNumber + 1;

            order.id = "${userController.user!.id
                .substring(0,5).toUpperCase()}"
                "${product.id.substring(0,5).toUpperCase()}"
                "${profile.name.substring(0,3)}"
                "${sales.orderNumber.toString()}";

            payment.finalAmount = product.salePrice!.amount;
            payment.tax = product.salePrice!.amount * AppPaymentConstants.mexicanTaxesAmount;


          }
          break;
        case SaleType.event:
          if (event.id.isNotEmpty) {
            displayedName = event.name;
            displayedDescription = event.description;
            displayedImgUrl = event.imgUrl;
            payment.price.amount = event.coverPrice!.amount;
            payment.price.currency = event.coverPrice!.currency;

            sales = await SalesFirestore().retrieveEventSales();
            sales.orderNumber = sales.orderNumber + 1;

            order.id = "${userController.user!.id
                .substring(0,5).toUpperCase()}"
                "${event.id.substring(0,5).toUpperCase()}"
                "${profile.name.substring(0,3).toUpperCase()}"
                "${sales.orderNumber.toString()}";

            payment.finalAmount = event.coverPrice!.amount;
            payment.tax = event.coverPrice!.amount * AppPaymentConstants.mexicanTaxesAmount;
          }
          break;
        case SaleType.booking:
          // TODO: Handle this case.
          break;
        case SaleType.releaseItem:
          if (releaseItem.id.isNotEmpty) {
            displayedName = releaseItem.name;
            displayedDescription = releaseItem.description;
            displayedImgUrl = releaseItem.imgUrl;

            if (releaseItem.isPhysical) {
              payment.price.amount = releaseItem.physicalPrice!.amount;
              payment.price.currency = releaseItem.physicalPrice!.currency;
            } else {
              payment.price.amount = releaseItem.digitalPrice!.amount;
              payment.price.currency = releaseItem.digitalPrice!.currency;
            }


            sales = await SalesFirestore().retrieveReleaseItemSales();
            sales.orderNumber = sales.orderNumber + 1;

            order.id = "${userController.user!.id
                .substring(0,5).toUpperCase()}"
                "${releaseItem.id.substring(0,5).toUpperCase()}"
                "${profile.name.substring(0,3).toUpperCase()}"
                "${sales.orderNumber.toString()}";

            payment.finalAmount = payment.price.amount;
            payment.tax = payment.finalAmount * AppPaymentConstants.mexicanTaxesAmount;
          }
          break;
      }


    } catch (e) {
      logger.e(e.toString());
    }

    isLoading = false;
    update([AppPageIdConstants.orderConfirmation]);
  }

  Future<void> confirmOrder() async {
    logger.i("Order was confirmed and would be created");
    // isLoading = true;
    String orderId = "";
    update([AppPageIdConstants.orderConfirmation]);
    try {
      orderId = await OrderFirestore().insert(order);
      if(orderId.isNotEmpty) {
        await SalesFirestore().updateOrderNumber(sales.orderNumber, order.saleType);
        await SalesFirestore().addOrderId(orderId: order.id, saleType: order.saleType);
        payment.orderId = order.id;
        Get.toNamed(AppRouteConstants.paymentGateway, arguments: [payment, order]);
      } else {
        Get.snackbar(
          MessageTranslationConstants.errorCreatingOrder.tr,
          MessageTranslationConstants.errorCreatingOrderMsg.tr,
          snackPosition: SnackPosition.bottom,);
      }
    } catch (e) {
      logger.e(e.toString());
    }

  }


}
