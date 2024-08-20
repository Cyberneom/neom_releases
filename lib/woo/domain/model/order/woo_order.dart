import 'package:json_annotation/json_annotation.dart';

import 'woo_billing.dart';
import 'woo_order_coupon_line.dart';
import 'woo_order_fee_line.dart';
import 'woo_order_line_item.dart';
import 'woo_order_metadata.dart';
import 'woo_order_refund.dart';
import 'woo_order_shipping_line.dart';
import 'woo_order_tax_line.dart';
import 'woo_shipping.dart';

part 'woo_order.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class WooOrder {

  int id;
  int parentId;
  String number;
  String orderKey;
  String createdVia; //"checkout" and others types
  String status;
  DateTime? dateCreated;
  DateTime? dateCreatedGmt;
  DateTime? dateModified;
  DateTime? dateModifiedGmt;
  String discountTotal;
  String discountTax;
  String shippingTotal;
  String shippingTax;
  String cartTax;
  String total;
  String totalTax;
  bool pricesIncludeTax;
  int customerId;
  String customerIdAddress;
  String customerUserAgent;
  String customerNote;
  WooBilling? billing;
  WooShipping? shipping;
  String paymentMethod;
  String paymentMethodTitle;
  String transactionId;

  DateTime? datePaid;
  DateTime? datePaidGmt;
  DateTime? dateCompleted;
  DateTime? dateCompletedGmt;

  String cartHash;

  List<WooOrderMetaData> metaData;
  List<WooOrderLineItem> lineItems;
  List<WooOrderTaxLine> taxLines;
  List<WooOrderShippingLine> shippingLines;
  List<WooOrderFeeLine> feeLines;
  List<WooOrderCouponLine> couponLines;
  List<WooOrderRefund> refunds;

  String paymentUrl;
  bool setPaid;
  bool isEditable;
  bool needsPayment;
  bool needsProcessing;

  String? wpcfDashboard;
  String? currencySymbol;
  Map<String, Map<String, dynamic>>? links;

  WooOrder({
    this.id = 0,
    this.parentId = 0,
    this.number = '',
    this.orderKey = '',
    this.createdVia = '',
    this.status = '',
    this.dateCreated,
    this.dateCreatedGmt,
    this.dateModified,
    this.dateModifiedGmt,
    this.discountTotal = '0',
    this.discountTax = '0',
    this.shippingTotal = '0',
    this.shippingTax = '0',
    this.cartTax = '0',
    this.total = '0',
    this.totalTax = '0',
    this.pricesIncludeTax = false,
    this.customerId = 0,
    this.customerIdAddress = '',
    this.customerUserAgent = '',
    this.customerNote = '',
    this.billing,
    this.shipping,
    this.paymentMethod = '',
    this.paymentMethodTitle = '',
    this.transactionId = '',
    this.datePaid,
    this.datePaidGmt,
    this.dateCompleted,
    this.dateCompletedGmt,
    this.cartHash = '',
    this.metaData = const [],
    this.lineItems = const [],
    this.taxLines = const [],
    this.shippingLines = const [],
    this.feeLines = const [],
    this.couponLines = const [],
    this.refunds = const [],
    this.paymentUrl = '',
    this.setPaid = false,
    this.isEditable = false,
    this.needsPayment = false,
    this.needsProcessing = false,
    this.wpcfDashboard,
    this.currencySymbol,
    this.links,
  });

  factory WooOrder.fromJson(Map<String, dynamic> json) =>
      _$WooOrderFromJson(json);

  Map<String, dynamic> toJson() => _$WooOrderToJson(this);

}
