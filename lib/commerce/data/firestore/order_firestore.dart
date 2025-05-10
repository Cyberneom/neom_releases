
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_commons/core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:uuid/uuid.dart'; // Add this import for UUID generation

import '../../domain/models/transaction_order.dart';
import '../../domain/repository/order_repository.dart';

class OrderFirestore implements OrderRepository {

  final orderReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.orders);

  @override
  Future<String> insert(TransactionOrder order) async {
    AppUtilities.logger.d("Inserting order ${order.id}");

    String orderId = '';
    try {

      if(order.id.isNotEmpty) {
        await orderReference.doc(order.id).set(order.toJSON());
      } else {
        var uuid = const Uuid();
        order.id = uuid.v4();
        await orderReference.doc(order.id).set(order.toJSON());
        // DocumentReference documentReference = await orderReference.add(order.toJSON());
        // order.id = documentReference.id;
      }
      orderId = order.id;
      AppUtilities.logger.d("Order for ${order.description} was added with id $orderId");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return orderId;

  }


  @override
  Future<bool> remove(TransactionOrder order) async {
    AppUtilities.logger.d("Removing product ${order.id}");

    try {
      await orderReference.doc(order.id).delete();
      AppUtilities.logger.d("Order ${order.id} was removed");
      return true;

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<TransactionOrder> retrieveOrder(String orderId) async {
    AppUtilities.logger.d("Retrieving Order for id $orderId");
    TransactionOrder order = TransactionOrder();

    try {

      DocumentSnapshot documentSnapshot = await orderReference.doc(orderId).get();

      if (documentSnapshot.exists) {
        AppUtilities.logger.d("Snapshot is not empty");
          order = TransactionOrder.fromJSON(documentSnapshot.data());
          order.id = documentSnapshot.id;
          AppUtilities.logger.d(order.toString());
        AppUtilities.logger.d("Order ${order.id} was retrieved");
      } else {
        AppUtilities.logger.w("Order ${order.id} was not found");
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return order;
  }


  @override
  Future<Map<String, TransactionOrder>> retrieveFromList(List<String> orderIds) async {
    AppUtilities.logger.d("Getting orders from list");

    Map<String, TransactionOrder> orders = {};

    try {
      QuerySnapshot querySnapshot = await orderReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          if(orderIds.contains(documentSnapshot.id)){
            AppUtilities.logger.d("DocumentSnapshot with ${documentSnapshot.id} about to be parsed");
            TransactionOrder order = TransactionOrder.fromJSON(documentSnapshot.data());
            order.id = documentSnapshot.id;
            AppUtilities.logger.t("Order ${order.id} was retrieved with details");
            orders[order.id] = order;
          }
        }
      }

      AppUtilities.logger.d("${orders.length} Orders were retrieved");
    } catch (e) {
      AppUtilities.logger.e(e);
    }
    return orders;
  }



  @override
  Future<bool> addInvoiceId({required String orderId, required String invoiceId}) async {
    AppUtilities.logger.d("Invoice $invoiceId would be added to order $orderId");

    try {
      DocumentSnapshot documentSnapshot = await orderReference
          .doc(orderId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.invoiceIds: FieldValue.arrayUnion([invoiceId])
      });
      AppUtilities.logger.d("Invoice $invoiceId is now at Order $orderId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> removeInvoiceId({required String orderId, required String invoiceId}) async {
    AppUtilities.logger.d("Invoice $invoiceId would be removed from order $orderId");

    try {
      DocumentSnapshot documentSnapshot = await orderReference
          .doc(orderId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.invoiceIds: FieldValue.arrayRemove([invoiceId])
      });
      AppUtilities.logger.d("Invoice $invoiceId was removed from Order $orderId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> addPaymentId({required String orderId, required String paymentId}) async {
    AppUtilities.logger.d("Payment $paymentId would be added to order $orderId");

    try {
      DocumentSnapshot documentSnapshot = await orderReference
          .doc(orderId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.paymentIds: FieldValue.arrayUnion([paymentId])
      });
      AppUtilities.logger.d("Payment $paymentId is now at Order $orderId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> removePaymentId({required String orderId, required String paymentId}) async {
    AppUtilities.logger.d("Payment $paymentId would be removed from order $orderId");

    try {
      DocumentSnapshot documentSnapshot = await orderReference
          .doc(orderId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.paymentIds: FieldValue.arrayRemove([paymentId])
      });
      AppUtilities.logger.d("Payment $paymentId was removed from Order $orderId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }


}
