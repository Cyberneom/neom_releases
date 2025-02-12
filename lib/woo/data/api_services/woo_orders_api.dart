import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/app_user.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';

import '../../domain/model/order/woo_billing.dart';
import '../../domain/model/order/woo_order.dart';
import '../../domain/model/order/woo_order_line_item.dart';
import '../../domain/model/order/woo_shipping.dart';
import '../../utils/constants/woo_constants.dart';
import '../../utils/enums/woo_order_status.dart';
import '../../utils/enums/woo_payment_method.dart';
import 'woo_products_api.dart';

class WooOrdersApi {

  static Future<String> createOrder(String email, List<WooOrderLineItem> orderLineItems, {
    String? customerId, WooBilling? billingAddress, WooShipping? shippingAddress, WooOrderStatus orderStatus = WooOrderStatus.processing}) async {

    String url = '${AppFlavour.getWooUrl()}/orders';
    String credentials = base64Encode(utf8.encode('${AppFlavour.getWooClientKey()}:${AppFlavour.getWooClientSecret()}'));


    WooOrder newOrder = WooOrder(
      paymentMethod: WooPaymentMethod.bacs.name,
      paymentMethodTitle: WooPaymentMethod.bacs.name,
      status: orderStatus.value,
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

    String orderId = '';

    if (response.statusCode == 201) {
      AppUtilities.logger.i('Order created successfully!');
      // Decodifica la respuesta JSON
      final responseData = jsonDecode(response.body);
      // Obtén el orderId de la respuesta
      orderId = responseData['id'].toString();
    } else {
      AppUtilities.logger.e('Failed to create order: ${response.statusCode}');
      AppUtilities.logger.e('Response: ${response.body}');
    }

    return orderId;
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

  static Future<String> createSessionOrder(AppUser user, String itemName, int quantity,{bool isNupale = false}) async {
    AppUtilities.logger.d('Processing Nupale Session Order of $quantity for $itemName');

    String orderId = '';
    String variationId = isNupale ? await WooProductsApi.getNupaleVariationId(itemName) :  await WooProductsApi.getCaseteVariationId(itemName);;

    if(variationId.isNotEmpty) {
      List<WooOrderLineItem> lineItems = [
        WooOrderLineItem(
          productId: WooConstants.nupaleProductId,
          variationId: int.parse(variationId),
          quantity: quantity,
        )
      ];

      WooBilling billingAddress = WooBilling(
          firstName: user.name,
          lastName: user.lastName,
          address1: '',
          city: user.homeTown,
          postcode: '',
          country: user.countryCode,
          email: user.email,
          phone: user.phoneNumber);

      orderId = await createOrder(user.email, lineItems, billingAddress: billingAddress, orderStatus: WooOrderStatus.nupaleSession);

    }

    return orderId;
  }

}
