import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_commons/core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import '../../domain/models/payment.dart';
import '../../domain/repository/payment_repository.dart';
import '../../utils/enums/payment_status.dart';

class PaymentFirestore implements PaymentRepository {

  var logger = AppUtilities.logger;
  final paymentReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.payments);

  @override
  Future<Payment> retrievePayment(String paymentId) async {
    logger.d("Retrieving Payment for id $paymentId");
    Payment payment = Payment();

    try {

      DocumentSnapshot documentSnapshot = await paymentReference.doc(paymentId).get();

      if (documentSnapshot.exists) {
        logger.d("Snapshot is not empty");
          payment = Payment.fromJSON(documentSnapshot.data());
          payment.id = documentSnapshot.id;
          logger.d(payment.toString());
        logger.d("Payment ${payment.id} was retrieved");
      } else {
        logger.w("Payment ${payment.id} was not found");
      }

    } catch (e) {
      logger.e(e.toString());
    }
    return payment;
  }


  @override
  Future<String> insert(Payment payment) async {
    logger.d("Inserting payment ${payment.id}");
    String paymentId = "";

    try {

      if(payment.id.isNotEmpty) {
        await paymentReference.doc(payment.id).set(payment.toJSON());
        paymentId = payment.id;
      } else {
        DocumentReference documentReference = await paymentReference
            .add(payment.toJSON());
        paymentId = documentReference.id;
        payment.id = paymentId;
        
      }
      logger.i("Payment for Order ${payment.orderId} was added with id ${payment.id}");
    } catch (e) {
      logger.e(e.toString());
    }

    return paymentId;

  }


  @override
  Future<bool> remove(Payment payment) async {
    logger.d("Removing payment ${payment.id}");

    try {
      await paymentReference.doc(payment.id).delete();
      logger.d("Payment ${payment.id} was removed");
      return true;

    } catch (e) {
      logger.e(e.toString());      
    }
    return false;
  }

  @override
  Future<bool> updatePaymentStatus(String paymentId, PaymentStatus paymentStatus) async {
    logger.d("Updating Payment Status for Payment Id $paymentId to ${paymentStatus.name}");

    try {
      DocumentSnapshot documentSnapshot = await paymentReference.doc(paymentId).get();
      await documentSnapshot.reference
          .update({AppFirestoreConstants.status: paymentStatus.name});


      logger.d("Payment $paymentId status was updated to ${paymentStatus.name}");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("Payment $paymentId status was not updated");
    return false;
  }


  @override
  Future<Map<String, Payment>> retrieveFromList(List<String> paymentIds, {PaymentStatus? status}) async {
    logger.d("Getting payments from list");

    Map<String, Payment> payments = {};

    try {
      QuerySnapshot querySnapshot = await paymentReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          if(paymentIds.contains(documentSnapshot.id)){
            Payment payment = Payment.fromJSON(documentSnapshot.data());
            payment.id = documentSnapshot.id;
            logger.d("Payment ${payment.id} was retrieved with details");
            if(status != null && payment.status == status) {
              payments[payment.id] = payment;
            } else {
              payments[payment.id] = payment;
            }
          }
        }
      }

      logger.d("${payments.length} Payments were retrieved");
    } catch (e) {
      logger.e(e);
    }
    return payments;
  }

}
