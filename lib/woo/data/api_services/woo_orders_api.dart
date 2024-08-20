import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';

import '../../domain/model/order/woo_billing.dart';
import '../../domain/model/order/woo_order.dart';
import '../../domain/model/order/woo_order_line_item.dart';
import '../../domain/model/order/woo_shipping.dart';
import '../../utils/enums/woo_order_status.dart';
import '../../utils/enums/woo_payment_method.dart';
import 'woo_products_api.dart';

class WooOrdersApi {

  static Future<void> createOrder(String email, List<WooOrderLineItem> orderLineItems,
      {String? customerId, WooBilling? billingAddress, WooShipping? shippingAddress}) async {

    String url = '${AppFlavour.getWooUrl()}/orders';
    String credentials = base64Encode(utf8.encode('${AppFlavour.getWooClientKey()}:${AppFlavour.getWooClientSecret()}'));


    WooOrder newOrder = WooOrder(
      // customerId: customerId,
      // customerEmail: email,
      paymentMethod: WooPaymentMethod.bacs.toString(),
      paymentMethodTitle: WooPaymentMethod.bacs.toString(),
      status: WooOrderStatus.processing.toString(),
      lineItems: orderLineItems,
      billing: billingAddress,
      shipping: shippingAddress,
    );

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(newOrder.toJson()),
    );

    if (response.statusCode == 201) {
      AppUtilities.logger.i('Order created successfully!');
    } else {
      AppUtilities.logger.i('Failed to create order: ${response.statusCode}');
      AppUtilities.logger.i('Response: ${response.body}');
    }
  }

  static Future<List<WooOrder>> getOrders({perPage = 25, page = 1, WooOrderStatus? status}) async {
    AppUtilities.logger.i('getOrders');

    String url = '${AppFlavour.getWooUrl()}/orders?page=$page&per_page=$perPage';
    if(status != null) url = '$url&status=${status.name}';
    String credentials = base64Encode(utf8.encode('${AppFlavour.getWooClientKey()}:${AppFlavour.getWooClientSecret()}'));

    List<WooOrder> wooOrders = [];

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> ordersJson = jsonDecode(response.body);
      AppUtilities.logger.i(ordersJson.toString());
      for (var json in ordersJson) {
        WooOrder wooOrder = WooOrder.fromJson(json);
        if(json['id'].toString() == '6364') {
          AppUtilities.logger.i("");
        }
        AppUtilities.logger.i(json.toString());
        wooOrders.add(wooOrder);
      }
      // return ordersJson.map((orderJson) => WooOrder.fromJSON(orderJson)).toList();
    } else {
      AppUtilities.logger.e('Failed to fetch orders: ${response.statusCode}');
      AppUtilities.logger.e('Response: ${response.body}');
    }

    return wooOrders;
  }

  static Future<void> processNupaleOrder(int productId, String monthYear, int itemId, int quantity) async {
    String variationId = await WooProductsApi.getVariationId(productId, monthYear, optionId: itemId);

    if (variationId.isEmpty) {
      // Variación no existe, crear variación y luego orden
      variationId = await WooProductsApi.createVariation(productId, monthYear, [itemId.toString()]);
    }
    List<WooOrderLineItem> lineItems = [WooOrderLineItem(productId: productId, variationId: itemId, quantity: quantity,)];
    await createOrder('escritoresmxi@gmail.com', lineItems);
  }

}
