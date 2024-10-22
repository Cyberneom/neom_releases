import 'dart:convert';
import 'dart:core';


import 'package:flutter/foundation.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:http/http.dart' as http;

import '../domain/models/stripe_price.dart';
import '../domain/models/stripe_product.dart';
import '../domain/models/stripe_session.dart';


class StripeService {


  static Future<StripeCheckoutSession> createCheckoutSessionUrl(String email) async {

    String url = 'https://api.stripe.com/v1/checkout/sessions';
    StripeCheckoutSession checkoutSession = StripeCheckoutSession();

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${kDebugMode ? AppFlavour.getStripeSecretTestKey() : AppFlavour.getStripeSecretLiveKey()}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_method_types[]': 'card',
          'mode': 'subscription',
          'customer_email': email,
          'line_items[0][price]': kDebugMode ? AppFlavour.getStripeTestSuscriptionPriceId() : AppFlavour.getStripeSuscriptionPriceId(),
          'line_items[0][quantity]': '1',
          'success_url': 'https://www.escritoresmxi.org/suscripcion-confirmada',
          'cancel_url': 'https://www.escritoresmxi.org/suscripcion-fallida',
        },
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        AppUtilities.logger.i('Checkout session created: ${responseData['id']}');
        checkoutSession.id = responseData['id'];
        checkoutSession.url= responseData['url'];
      } else {
        AppUtilities.logger.w('Error: ${responseData['error']['message']}');
      }
    } catch (e) {
      AppUtilities.logger.e('Error creating checkout session: $e');
    }

    return checkoutSession;
  }

  static Future<void> createSubscription({
    required String email,
    required String paymentMethodId,
  }) async {
    try {
    } catch (e) {
      print('Error creating subscription: $e');
    }
  }

  static Future<String> getSubscriptionId(String sessionId) async {
    String url = 'https://api.stripe.com/v1/checkout/sessions/$sessionId';
    String subscriptionId = '';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${kDebugMode ? AppFlavour.getStripeSecretTestKey() : AppFlavour.getStripeSecretLiveKey()}',
      },
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200) {
      subscriptionId = responseData['subscription'] ?? '';
      if (subscriptionId.isNotEmpty) {
        AppUtilities.logger.i('Subscription ID: $subscriptionId');
        // Aquí puedes guardar el subscriptionId o hacer algo con él
      } else {
        AppUtilities.logger.w('No subscription found for this session.');
      }
    } else {
      AppUtilities.logger.e('Error fetching session: ${responseData['error']['message']}');
    }

    return subscriptionId;
  }

  static Future<String> getCustomerId(String sessionId) async {
    String url = 'https://api.stripe.com/v1/checkout/sessions/$sessionId';
    String customerId = '';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${kDebugMode ? AppFlavour.getStripeSecretTestKey() : AppFlavour.getStripeSecretLiveKey()}',
      },
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200) {
      customerId = responseData['customer'] ?? '';
      if (customerId.isNotEmpty) {
        AppUtilities.logger.i('Customer ID: $customerId');
        // Aquí puedes guardar el subscriptionId o hacer algo con él
      } else {
        AppUtilities.logger.w('No subscription found for this session.');
      }
    } else {
      AppUtilities.logger.e('Error fetching session: ${responseData['error']['message']}');
    }

    return customerId;
  }

  static Future<bool> cancelSubscription(String subscriptionId) async {
    String url = 'https://api.stripe.com/v1/subscriptions/$subscriptionId';

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${kDebugMode ? AppFlavour.getStripeSecretTestKey() : AppFlavour.getStripeSecretLiveKey()}',
      },
    );

    if (response.statusCode == 200) {
      AppUtilities.logger.i('Subscription cancelled successfully.');
      return true;
    } else {
      AppUtilities.logger.e('Error cancelling subscription: ${json.decode(response.body)['error']['message']}');
    }

    return false;
  }

  static Future<void> getSubscriptionDetails(String subscriptionId) async {
    String url = 'https://api.stripe.com/v1/subscriptions/$subscriptionId';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${kDebugMode ? AppFlavour.getStripeSecretTestKey() : AppFlavour.getStripeSecretLiveKey()}',
      },
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200) {
      print('Subscription status: ${responseData['status']}');
      // Puedes manejar los diferentes estados, como "active", "canceled", etc.
    } else {
      print('Error fetching subscription details: ${responseData['error']['message']}');
    }
  }

  static Future<void> getCustomerIdByEmail(String email) async {
    String url = 'https://api.stripe.com/v1/customers?email=$email';  // Filtra por email

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${kDebugMode ? AppFlavour.getStripeSecretTestKey() : AppFlavour.getStripeSecretLiveKey()}',
      },
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200) {
      List customers = responseData['data'];
      if (customers.isNotEmpty) {
        String customerId = customers[0]['id'];  // Obtén el primer cliente que coincide
        print('Customer ID: $customerId');
        // Ahora puedes usar el customerId para obtener las suscripciones
        await getSubscriptionsFromCustomer(customerId);
      } else {
        print('No customer found with that email.');
      }
    } else {
      print('Error fetching customer: ${responseData['error']['message']}');
    }
  }

  // Listar las suscripciones usando el Customer ID
  static Future<void> getSubscriptionsFromCustomer(String customerId) async {
    String url = 'https://api.stripe.com/v1/subscriptions?customer=$customerId';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${kDebugMode ? AppFlavour.getStripeSecretTestKey() : AppFlavour.getStripeSecretLiveKey()}',
      },
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200) {
      List subscriptions = responseData['data'];
      if (subscriptions.isNotEmpty) {
        for (var subscription in subscriptions) {
          String subscriptionId = subscription['id'];
          print('Subscription ID: $subscriptionId');
          print('Status: ${subscription['status']}');
          // Aquí puedes manejar el subscriptionId o guardarlo en tu base de datos
        }
      } else {
        print('No subscriptions found for this customer.');
      }
    } else {
      print('Error fetching subscriptions: ${responseData['error']['message']}');
    }
  }

  static Future<List<StripeProduct>> getProducts() async {
    String url = 'https://api.stripe.com/v1/products';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${kDebugMode ? AppFlavour.getStripeSecretTestKey() : AppFlavour.getStripeSecretLiveKey()}',
        },
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        List productsData = responseData['data'];
        List<StripeProduct> products = productsData
            .map<StripeProduct>((productData) => StripeProduct.fromJSON(productData))
            .toList();

        AppUtilities.logger.d('Products fetched successfully.');
        return products;
      } else {
        AppUtilities.logger.e('Error fetching products: ${responseData['error']['message']}');
        return [];
      }
    } catch (e) {
      AppUtilities.logger.e('Error fetching products: $e');
      return [];
    }
  }

  static Future<StripeProduct?> getProductById(String productId) async {
    String url = 'https://api.stripe.com/v1/products/$productId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${kDebugMode ? AppFlavour.getStripeSecretTestKey() : AppFlavour.getStripeSecretLiveKey()}',
        },
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        StripeProduct product = StripeProduct.fromJSON(responseData);
        AppUtilities.logger.d('Product fetched: $productId');
        return product;
      } else {
        AppUtilities.logger.e('Error fetching product: ${responseData['error']['message']}');
        return null;
      }
    } catch (e) {
      AppUtilities.logger.e('Error fetching product: $e');
      return null;
    }
  }

  static Future<List<StripePrice>> getProductPrices(String productId) async {
    String url = 'https://api.stripe.com/v1/prices?product=$productId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${kDebugMode ? AppFlavour.getStripeSecretTestKey() : AppFlavour.getStripeSecretLiveKey()}',
        },
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        List pricesData = responseData['data'];
        List<StripePrice> prices = pricesData
            .map<StripePrice>((priceData) => StripePrice.fromJSON(priceData))
            .toList();

        AppUtilities.logger.d('Prices fetched for product: $productId');
        return prices;
      } else {
        AppUtilities.logger.e('Error fetching prices: ${responseData['error']['message']}');
        return [];
      }
    } catch (e) {
      AppUtilities.logger.e('Error fetching prices: $e');
      return [];
    }
  }

  static Future<Map<String, List<StripePrice>>> getRecurringPricesFromStripe() async {
    AppUtilities.logger.d('getRecurringPricesFromStripe');
    Map<String, List<StripePrice>> recurringProductPrices = {};

    try {
      // Fetch products from Stripe
      List<StripeProduct> products = await StripeService.getProducts();


      for (StripeProduct product in products) {
        // Fetch prices for each product
        List<StripePrice> prices = await StripeService.getProductPrices(product.id);

        // Filter only recurring prices
        List<StripePrice> recurringPrices = prices
            .map((price) => price)
            .where((price) => price.interval != null).toList();

        if (recurringPrices.isNotEmpty) {
          // Store product info and recurring prices
          recurringProductPrices[product.id] = prices;
        }
      }

      AppUtilities.logger.d("Fetched Stripe Subscription Products & Prices successfully");
      return recurringProductPrices;
    } catch (e) {
      AppUtilities.logger.e("Error fetching recurring prices: $e");
    }

    return recurringProductPrices;
  }


}
