import '../models/purchase_order.dart';

abstract class OrderRepository {

  Future<String> insert(PurchaseOrder order);
  Future<bool> remove(PurchaseOrder order);
  Future<PurchaseOrder> retrieveOrder(String orderId);
  Future<Map<String, PurchaseOrder>> retrieveFromList(List<String> orderIds);
  Future<bool> addInvoiceId({required String orderId, required String invoiceId});
  Future<bool> removeInvoiceId({required String orderId, required String invoiceId});
  Future<bool> addPaymentId({required String orderId, required String paymentId});
  Future<bool> removePaymentId({required String orderId, required String paymentId});

}
