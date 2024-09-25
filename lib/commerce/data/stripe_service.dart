import 'dart:convert';
import 'dart:core';


import 'package:flutter/foundation.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:http/http.dart' as http;

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



}
