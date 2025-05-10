import '../models/transaction_order.dart';

abstract class OrderRepository {

  Future<String> insert(TransactionOrder order);
  Future<bool> remove(TransactionOrder order);
  Future<TransactionOrder> retrieveOrder(String orderId);
  Future<Map<String, TransactionOrder>> retrieveFromList(List<String> orderIds);
  Future<bool> addInvoiceId({required String orderId, required String invoiceId});
  Future<bool> removeInvoiceId({required String orderId, required String invoiceId});
  Future<bool> addPaymentId({required String orderId, required String paymentId});
  Future<bool> removePaymentId({required String orderId, required String paymentId});

}
