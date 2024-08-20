import '../../utils/enums/payment_status.dart';
import '../models/payment.dart';

abstract class PaymentRepository {

  Future<String> insert(Payment payment);
  Future<bool> remove(Payment payment);
  Future<Payment> retrievePayment(String paymentId);
  Future<bool> updatePaymentStatus(String paymentId, PaymentStatus paymentStatus);
  Future<Map<String, Payment>> retrieveFromList(List<String> paymentIds, {PaymentStatus? status});
  Future<List<Payment>> retrieveByOrderId(String orderId);

}
