// import 'package:enum_to_string/enum_to_string.dart';
//
// import '../utils/enums/woo_order_status.dart';
// import '../utils/enums/woo_payment_method.dart';
// import 'woo_line_item.dart';
// import 'woo_shipping_address.dart';
//
// class WooOrder {
//   String? customerId;
//   String? customerEmail;
//   WooPaymentMethod paymentMethod;
//   WooPaymentMethod paymentMethodTitle;
//   WooOrderStatus status;
//   List<WooLineItem> lineItems;
//   ShippingAddress? billingAddress;
//   ShippingAddress? shippingAddress;
//
//   WooOrder({
//     this.customerId,
//     this.customerEmail,
//     required this.paymentMethod,
//     required this.paymentMethodTitle,
//     this.status = WooOrderStatus.processing,
//     required this.lineItems,
//     this.billingAddress,
//     this.shippingAddress,
//   });
//
//   // Convert a WooOrder object to a JSON map
//   Map<String, dynamic> toJSON() {
//     final Map<String, dynamic> data = {
//       'customer_id': customerId,
//       'payment_method': paymentMethod.name,
//       'payment_method_title': paymentMethodTitle.name,
//       'line_items': lineItems.map((item) => item.toJSON()).toList(),
//       'meta_data': [
//         {
//           'key': 'order_origin',
//           'value': 'EMXI App',
//           '_wc_order_attribution_utm_referrer': 'www.gigmeout.io',
//           '_wc_order_attribution_utm_source': 'EMXI App',
//           '_wc_order_attribution_utm_medium': 'Mobile Appu',
//         },
//       ],
//       'status': status.value
//     };
//
//     if (customerId != null) {
//       data['customer_id'] = customerId;
//     } else if (billingAddress != null && customerEmail != null) {
//       data['billing'] = billingAddress!.toJSON();
//       data['billing']['email'] = customerEmail;
//     }
//
//     if (shippingAddress != null) {
//       data['shipping'] = shippingAddress!.toJSON();
//     }
//
//
//     return data;
//   }
//
//   // Create a WooOrder object from a JSON map
//   factory WooOrder.fromJSON(Map<String, dynamic> json) {
//     return WooOrder(
//       customerId: json['customer_id'].toString(),
//       customerEmail: json['billing']?['email'],
//       paymentMethod: EnumToString.fromString(WooPaymentMethod.values, json['payment_method'] ?? WooPaymentMethod.bacs.name) ?? WooPaymentMethod.bacs,
//       paymentMethodTitle: EnumToString.fromString(WooPaymentMethod.values, json['payment_method_title'] ?? WooPaymentMethod.bacs.name) ?? WooPaymentMethod.bacs,
//       status: EnumToString.fromString(WooOrderStatus.values, json['status'] ?? WooOrderStatus.processing.name) ?? WooOrderStatus.processing,
//       lineItems: (json['line_items'] as List)
//           .map((item) => WooLineItem.fromJSON(item))
//           .toList(),
//       billingAddress: json['billing'] != null
//           ? ShippingAddress.fromJSON(json['billing'])
//           : null,
//       shippingAddress: json['shipping'] != null
//           ? ShippingAddress.fromJSON(json['shipping'])
//           : null,
//     );
//   }
// }
