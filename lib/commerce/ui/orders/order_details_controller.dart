import 'package:get/get.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/domain/model/booking.dart';
import 'package:neom_commons/core/domain/model/event.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/enums/sale_type.dart';

import '../../data/firestore/invoice_firestore.dart';
import '../../data/firestore/payment_firestore.dart';
import '../../domain/models/app_product.dart';
import '../../domain/models/invoice.dart';
import '../../domain/models/payment.dart';
import '../../domain/models/purchase_order.dart';

class OrderDetailsController extends GetxController with GetTickerProviderStateMixin {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxMap<String, Payment> _payments = <String, Payment>{}.obs;
  Map<String, Payment> get payments => _payments;
  set payments(Map<String, Payment> payments) => _payments.value = payments;

  final RxMap<String, Invoice> _invoices = <String, Invoice>{}.obs;
  Map<String, Invoice> get invoices => _invoices;
  set invoices(Map<String, Invoice> invoices) => _invoices.value = invoices;

  AppProfile profile = AppProfile();

  AppProduct? product;
  Event? event;
  Booking? booking;
  AppReleaseItem? releaseItem;

  PurchaseOrder order = PurchaseOrder();
  Payment payment = Payment();
  Invoice invoice = Invoice();
  double discountPercentage = 0.0;

  String displayedName = "";
  String displayedDescription = "";
  String displayedImgUrl = "";


  @override
  void onInit() async {
    super.onInit();
    logger.d("Order Details Controller Init");

    try {
      profile = userController.user!.profiles.first;

      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        if (Get.arguments[0] is PurchaseOrder) {
          order = Get.arguments[0];
        }
      }

      switch(order.saleType) {
        case SaleType.product:
          product = order.product!;
          break;
        case SaleType.event:
          event = order.event!;
          break;
        case SaleType.booking:
          booking = order.booking!;
          break;
        case SaleType.releaseItem:
          releaseItem = order.releaseItem;
          break;
      }

    } catch (e) {
      logger.i(e.toString());
    }

  }

  @override
  void onReady() async {
    try {

      if(order.paymentIds?.isNotEmpty ?? false) {
        payments = await PaymentFirestore().retrieveFromList(order.paymentIds!);
      }

      if(payments.isNotEmpty) {
        payment = payments.values.first;
      }

      if(payment.discountAmount > 0) {
        discountPercentage = ((100 * payment.discountAmount) / payment.price.amount).toPrecision(2);
      }

      if(order.invoiceIds?.isNotEmpty ?? false) {
        invoices = await InvoiceFirestore().retrieveFromList(order.invoiceIds!);
      }

      if(invoices.isNotEmpty) {
        invoice = invoices.values.first;
      }

      if(product?.id.isNotEmpty ?? false) {
        displayedName = product!.name;
        displayedDescription = product!.description;
      } else if (event?.id.isNotEmpty ?? false) {
        displayedName = event!.name;
        displayedDescription = event!.description;
        displayedImgUrl = event!.imgUrl;
      }

    } catch (e) {
      logger.e(e.toString());
    }

    isLoading = false;
    update([AppPageIdConstants.orderDetails]);
  }

}
