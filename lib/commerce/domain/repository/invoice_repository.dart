import '../models/invoice.dart';

abstract class InvoiceRepository {

  Future<String> insert(Invoice invoice);
  Future<bool> remove(Invoice invoice);
  Future<Invoice> retrieveInvoice(String invoiceId);
  Future<Map<String, Invoice>> retrieveFromList(List<String> invoiceIds);

}
