import 'package:get/get.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_coupon.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/enums/coupon_type.dart';

import '../../data/firestore/invoice_firestore.dart';
import '../../data/firestore/payment_firestore.dart';
import '../../domain/models/app_product.dart';
import '../../domain/models/invoice.dart';
import '../../domain/models/payment.dart';
import '../../domain/models/purchase_order.dart';

class OrderDetailsController extends GetxController with GetTickerProviderStateMixin {

  final userController = Get.find<UserController>();

  bool isButtonDisabled = false;
  bool isLoading = true;
  List<Payment> payments = [];
  List<Invoice> invoices = [];

  AppProfile profile = AppProfile();

  AppProduct? product;
  AppCoupon? coupon;
  ///DEPRECATED
  // Event? event;
  // Booking? booking;
  // AppReleaseItem? releaseItem;

  PurchaseOrder order = PurchaseOrder();
  Payment payment = Payment();
  Invoice invoice = Invoice();

  double discountAmount = 0.0;
  double discountPercentage = 0.0;

  String displayedName = "";
  String displayedDescription = "";
  // String displayedImgUrl = "";


  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.d("Order Details Controller Init");

    try {
      profile = userController.user.profiles.first;

      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        if (Get.arguments[0] is PurchaseOrder) {
          order = Get.arguments[0];
          product = order.product;
        }
        if(Get.arguments.length > 1) {
          coupon = Get.arguments[1];
        }
      }

      ///DEPRECATED
      // switch(order.saleType) {
      //   case SaleType.product:
      //     product = order.product!;
      //     break;
      //   case SaleType.event:
      //     event = order.event!;
      //     break;
      //   case SaleType.booking:
      //     booking = order.booking!;
      //     break;
      //   case SaleType.physicalItem:
      //     releaseItem = order.releaseItem;
      //     break;
      //   case SaleType.digitalItem:
      //     releaseItem = order.releaseItem;
      //     break;
      // }

    } catch (e) {
      AppUtilities.logger.i(e.toString());
    }

  }

  @override
  void onReady() async {
    try {

      payments = await PaymentFirestore().retrieveByOrderId(order.id);

      if(payments.isNotEmpty) payment = payments.first;

      if((product?.regularPrice != null && product?.salePrice != null) &&
        product?.regularPrice?.amount != product?.salePrice?.amount) {

        discountAmount = product!.regularPrice!.amount - product!.salePrice!.amount;
        discountPercentage = ((discountAmount/product!.regularPrice!.amount) * 100);

      } else if(coupon != null && coupon?.type != CouponType.productDiscount) {
        discountPercentage = coupon!.amount ;
      }

      if(order.invoiceIds?.isNotEmpty ?? false) {
        invoices = await InvoiceFirestore().retrieveFromList(order.invoiceIds!);
      }

      if(invoices.isNotEmpty) invoice = invoices.first;

      if(product?.id.isNotEmpty ?? false) {
        displayedName = product!.name;
        displayedDescription = product!.description;
      }
      ///DEPRECATED
      // else if (event?.id.isNotEmpty ?? false) {
      //   displayedName = event!.name;
      //   displayedDescription = event!.description;
      //   displayedImgUrl = event!.imgUrl;
      // }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoading = false;
    update([AppPageIdConstants.orderDetails]);
  }

}
