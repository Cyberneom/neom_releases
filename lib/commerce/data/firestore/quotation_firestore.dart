import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import '../../domain/models/app_quotation.dart';

class QuotationFirestore {

  final quotationReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.quotations);

  @override
  Future<AppQuotation> retrieve(String quotationId) async {
    AppUtilities.logger.d("Retrieving Quotation for id $quotationId");
    AppQuotation quotation = AppQuotation();  // Initialize with default values

    try {
      DocumentSnapshot documentSnapshot = await quotationReference.doc(quotationId).get();

      if (documentSnapshot.exists) {
        AppUtilities.logger.d("Snapshot is not empty");
        Map<String, dynamic> quotationJson = documentSnapshot.data() as Map<String, dynamic>;
        quotation = AppQuotation.fromJson(quotationJson);
        quotation.id = documentSnapshot.id;
        AppUtilities.logger.d(quotation.toString());
        AppUtilities.logger.d("Quotation ${quotation.id} was retrieved");
      } else {
        AppUtilities.logger.w("Quotation $quotationId was not found");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return quotation;
  }

  @override
  Future<String> insert(AppQuotation quotation) async {
    AppUtilities.logger.d("Inserting Quotation");
    String quotationId = quotation.id;

    try {
      if(quotationId.isEmpty) {
        DocumentReference documentReference = await quotationReference.add(quotation.toJson());
        quotationId = documentReference.id;
      } else {
        await quotationReference.doc(quotation.id).set(quotation.toJson());
      }


      AppUtilities.logger.i("Quotation was added with id $quotationId");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return quotationId;
  }

  @override
  Future<bool> remove(AppQuotation quotation) async {
    AppUtilities.logger.d("Removing Quotation ${quotation.id}");

    try {
      await quotationReference.doc(quotation.id).delete();
      AppUtilities.logger.d("Quotation ${quotation.id} was removed");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<List<AppQuotation>> retrieveFromList(List<String> quotationIds) async {
    AppUtilities.logger.d("Getting quotations from list");

    List<AppQuotation> quotations = [];

    try {
      QuerySnapshot querySnapshot = await quotationReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          if (quotationIds.contains(documentSnapshot.id)) {
            AppQuotation quotation = AppQuotation.fromJson(documentSnapshot.data() as Map<String, dynamic>);
            quotation.id = documentSnapshot.id;
            AppUtilities.logger.d("Quotation ${quotation.id} was retrieved with details");
            quotations.add(quotation);
          }
        }
      }

      AppUtilities.logger.d("${quotations.length} Quotations were retrieved");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return quotations;
  }

}
