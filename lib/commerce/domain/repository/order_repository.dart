import '../models/app_order.dart';

abstract class OrderRepository {

  Future<String> insert(AppOrder order);
  Future<bool> remove(AppOrder order);
  Future<AppOrder> retrieveOrder(String orderId);
  Future<Map<String, AppOrder>> retrieveFromList(List<String> orderIds);
  Future<bool> addInvoiceId({required String orderId, required String invoiceId});
  Future<bool> removeInvoiceId({required String orderId, required String invoiceId});
  Future<bool> addPaymentId({required String orderId, required String paymentId});
  Future<bool> removePaymentId({required String orderId, required String paymentId});

}
