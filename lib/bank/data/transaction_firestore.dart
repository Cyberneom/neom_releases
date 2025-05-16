import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_commons/core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import '../../commerce/domain/models/app_transaction.dart';
import '../../commerce/domain/repository/payment_repository.dart';
import '../../commerce/utils/enums/payment_status.dart';

class TransactionFirestore implements TransactionRepository {
  
  final transactionReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.transactions);

  @override
  Future<AppTransaction?> retrieve(String transactionId) async {
    AppUtilities.logger.d("Retrieving AppTransaction for id $transactionId");
    AppTransaction? transaction;

    try {

      DocumentSnapshot documentSnapshot = await transactionReference.doc(transactionId).get();

      if (documentSnapshot.exists) {
        AppUtilities.logger.d("Snapshot is not empty");
          transaction = AppTransaction.fromJSON(documentSnapshot.data());
          transaction.id = documentSnapshot.id;
          AppUtilities.logger.d(transaction.toString());
        AppUtilities.logger.d("AppTransaction ${transaction.id} was retrieved");
      } else {
        AppUtilities.logger.w("AppTransaction $transactionId was not found");
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return transaction;
  }


  @override
  Future<String> insert(AppTransaction transaction) async {
    AppUtilities.logger.d("Inserting transaction ${transaction.id}");
    String transactionId = "";

    try {

      if(transaction.id.isNotEmpty) {
        await transactionReference.doc(transaction.id).set(transaction.toJSON());
        transactionId = transaction.id;
      } else {
        DocumentReference documentReference = await transactionReference
            .add(transaction.toJSON());
        transactionId = documentReference.id;
        transaction.id = transactionId;
        
      }
      AppUtilities.logger.i("AppTransaction for Order ${transaction.orderId} was added with id ${transaction.id}");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return transactionId;

  }


  @override
  Future<bool> remove(AppTransaction transaction) async {
    AppUtilities.logger.d("Removing transaction ${transaction.id}");

    try {
      await transactionReference.doc(transaction.id).delete();
      AppUtilities.logger.d("AppTransaction ${transaction.id} was removed");
      return true;

    } catch (e) {
      AppUtilities.logger.e(e.toString());      
    }
    return false;
  }

  @override
  Future<bool> updateStatus(String transactionId, TransactionStatus status) async {
    AppUtilities.logger.d("Updating AppTransaction Status for AppTransaction Id $transactionId to ${status.name}");

    try {
      DocumentSnapshot documentSnapshot = await transactionReference.doc(transactionId).get();
      await documentSnapshot.reference
          .update({AppFirestoreConstants.status: status.name});


      AppUtilities.logger.d("AppTransaction $transactionId status was updated to ${status.name}");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("AppTransaction $transactionId status was not updated");
    return false;
  }


  @override
  Future<Map<String, AppTransaction>> retrieveFromList(List<String> transactionIds, {TransactionStatus? status}) async {
    AppUtilities.logger.d("Getting transactions from list");

    Map<String, AppTransaction> transactions = {};

    try {
      QuerySnapshot querySnapshot = await transactionReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          if(transactionIds.contains(documentSnapshot.id)){
            AppTransaction transaction = AppTransaction.fromJSON(documentSnapshot.data());
            transaction.id = documentSnapshot.id;
            AppUtilities.logger.d("AppTransaction ${transaction.id} was retrieved with details");
            if(status != null && transaction.status == status) {
              transactions[transaction.id] = transaction;
            } else {
              transactions[transaction.id] = transaction;
            }
          }
        }
      }

      AppUtilities.logger.d("${transactions.length} Transactions were retrieved");
    } catch (e) {
      AppUtilities.logger.e(e);
    }
    return transactions;
  }

  @override
  Future<List<AppTransaction>> retrieveByOrderId(String orderId) async {
    AppUtilities.logger.d("retrieveByOrderId");

    List<AppTransaction> transactions = [];

    try {
      QuerySnapshot snapshot = await transactionReference.get();

      for(var document in snapshot.docs) {
        AppTransaction transaction = AppTransaction.fromJSON(document.data());
        if(transaction.orderId == orderId) {
          transaction.id = document.id;
          transactions.add(transaction);
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return transactions;
  }
}
