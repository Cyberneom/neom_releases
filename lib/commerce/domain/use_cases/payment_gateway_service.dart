
import 'package:flutter_stripe/flutter_stripe.dart';

abstract class PaymentGatewayService {

  Future<void> handleStripePayment();
  Future<void> payWithAppCoins();
  Future<void> handlePaymentMethod(BillingDetails billingDetails);
  Future<void> handleProcessedPayment();
  Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency);
  Future<void> confirmIntent(String paymentIntentId);
  Future<Map<String, dynamic>> callNoWebhookPayEndpointIntentId({required String paymentIntentId});

}
