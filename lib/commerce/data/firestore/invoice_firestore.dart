import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import '../../domain/models/invoice.dart';
import '../../domain/repository/invoice_repository.dart';

class InvoiceFirestore implements InvoiceRepository {
  
  final invoiceReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.invoices);

  @override
  Future<Invoice> retrieveInvoice(String invoiceId) async {
    AppUtilities.logger.d("Retrieving Invoice for id $invoiceId");
    Invoice invoice = Invoice();

    try {
      DocumentSnapshot documentSnapshot = await invoiceReference.doc(invoiceId).get();

      if (documentSnapshot.exists) {
        AppUtilities.logger.d("Snapshot is not empty");
          invoice = Invoice.fromJSON(documentSnapshot.data());
          invoice.id = documentSnapshot.id;
          AppUtilities.logger.d(invoice.toString());
        AppUtilities.logger.d("Invoice ${invoice.id} was retrieved");
      } else {
        AppUtilities.logger.w("Invoice ${invoice.id} was not found");
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return invoice;
  }


  @override
  Future<String> insert(Invoice invoice) async {
    AppUtilities.logger.d("Inserting invoice");
    String invoiceId = "";

    try {
        DocumentReference documentReference = await invoiceReference
            .add(invoice.toJSON());
        invoiceId = documentReference.id;
        invoice.id = invoiceId;

      AppUtilities.logger.i("Invoice for Order ${invoice.orderId} was added with id ${invoice.id}");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return invoiceId;

  }


  @override
  Future<bool> remove(Invoice invoice) async {
    AppUtilities.logger.d("Removing invoice ${invoice.id}");

    try {
      await invoiceReference.doc(invoice.id).delete();
      AppUtilities.logger.d("Invoice ${invoice.id} was removed");
      return true;

    } catch (e) {
      AppUtilities.logger.e(e.toString());      
    }
    return false;
  }


  @override
  Future<List<Invoice>> retrieveFromList(List<String> invoiceIds) async {
    AppUtilities.logger.d("Getting invoices from list");

    List<Invoice> invoices = [];

    try {
      QuerySnapshot querySnapshot = await invoiceReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          if(invoiceIds.contains(documentSnapshot.id)){
            Invoice invoice = Invoice.fromJSON(documentSnapshot.data());
            invoice.id = documentSnapshot.id;
            AppUtilities.logger.d("Invoice ${invoice.id} was retrieved with details");
            invoices.add(invoice);
          }
        }
      }

      AppUtilities.logger.d("${invoices.length} Orders were retrieved");
    } catch (e) {
      AppUtilities.logger.e(e);
    }
    return invoices;
  }


}
