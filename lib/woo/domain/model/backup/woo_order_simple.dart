// import 'woo_billing.dart';
// import 'woo_order_coupon_line.dart';
// import 'woo_order_fee_line.dart';
// import 'woo_order_line_item.dart';
// import 'woo_order_metadata.dart';
// import 'woo_order_refund.dart';
// import 'woo_order_shipping_line.dart';
// import 'woo_order_tax_line.dart';
// import 'woo_shipping.dart';
//
// class WooOrderSimple {
//
//   int id;
//   int parentId;
//   String status; //Status Order Type
//   String currency; //MXN
//   String version;
//   bool pricesIncludeTax; //false
//   DateTime dateCreated;
//   DateTime dateModified;
//   double discountTotal;
//   double discountTax;
//   double shippingTotal;
//   double shippingTax;
//   double cartTax;
//   double total;
//   double totalTax;
//   int customerId; //customer_id -> user.email
//   String orderKey;
//
//   WooBilling billing;
//   WooShipping shipping;
//
//   String paymentMethod; //Stripe and others
//   String paymentMethodTitle; //Tarjeta de Credito (Strip)
//   String transactionId;
//   String customerIpAddress;
//   String customerUserAgent;
//   String createdVia; //"checkout" and others types
//   String customerNote; //"customer_noter" and others types
//
//   DateTime dateCompleted;
//   DateTime datePaid;
//
//   String cartHash; //cart_hash
//   int number;
//
//   List<WooOrderMetaData> metaData; //meta_data
//   List<WooOrderLineItem> lineItems;
//   List<WooOrderTaxLine> taxLines;
//   List<WooOrderShippingLine> shippingLines;
//   List<WooOrderFeeLine> feeLines;
//   List<WooOrderCouponLine> couponLines;
//   List<WooOrderRefund> refunds;
//
//   String paymentUrl;
//   bool setPaid;
//
//   bool isEditable;
//   bool needsPayment;
//   bool needsProcessing;
//
//   DateTime dateCreatedGmt;
//   DateTime dateModifiedGmt;
//   DateTime dateCompletedGmt;
//   DateTime datePaidGmt;
//
//   String? wpcfDashboard;
//   String? currencySymbol;
//   Map<String, Map<String, dynamic>>? links;
//
//   WooOrderSimple({
//     this.id,
//     this.parentId,
//     this.status,
//     this.currency,
//     this.version,
//     this.pricesIncludeTax,
//     this.dateCreated,
//     this.dateModified,
//     this.discountTotal,
//     this.discountTax,
//     this.shippingTotal,
//     this.shippingTax,
//     this.cartTax,
//     this.total,
//     this.totalTax,
//     this.customerId,
//     this.orderKey,
//     this.billing,
//     this.shipping,
//     this.paymentMethod,
//     this.paymentMethodTitle,
//     this.transactionId,
//     this.customerIpAddress,
//     this.customerUserAgent,
//   });
//
//   factory WooOrderSimple.fromJson(Map<String, dynamic> json) => WooOrderSimple(
//     id: json['id'] as int,
//     parentId: json['parent_id'] as int,
//     status: json['status'] as String,
//     currency: json['currency'] as String,
//     version: json['version'] as String,
//     pricesIncludeTax: json['prices_include_tax'] as bool,
//     dateCreated: DateTime.parse(json['date_created'] as String),
//     dateModified: DateTime.parse(json['date_modified'] as String),
//     discountTotal: double.parse(json['discount_total'] as String),
//     discountTax: double.parse(json['discount_tax'] as String),
//     shippingTotal: double.parse(json['shipping_total'] as String),
//     shippingTax: double.parse(json['shipping_tax'] as String),
//     cartTax: double.parse(json['cart_tax'] as String),
//     total: double.parse(json['total'] as String),
//     totalTax: double.parse(json['total_tax'] as String),
//     customerId: json['customer_id'] as int,
//     orderKey: json['order_key'] as String,
//     billing: WooBilling.fromJson(json['billing'] as Map<String, dynamic>),
//     shipping: WooShipping.fromJson(json['shipping'] as Map<String, dynamic>),
//     paymentMethod: json['payment_method'] as String,
//     paymentMethodTitle: json['payment_method_title'] as String,
//     transactionId: json['transaction_id'] as String,
//     customerIpAddress: json['customer_ip_address'] as String,
//     customerUserAgent: json['customer_user_agent'] as String,
//   );
// }
//
//
