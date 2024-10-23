import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_commons/core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_commons/core/domain/model/subscription_plan.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/enums/product_type.dart';
import 'package:neom_commons/core/utils/enums/subscription_level.dart';
import '../../domain/models/app_product.dart';
import '../../domain/repository/product_repository.dart';

class SubscriptionPlanFirestore {
  
  final subscriptionPlanReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.subscriptionPlans);

  @override
  Future<Map<String, SubscriptionPlan>> getAll() async {
    AppUtilities.logger.d("Retrieving Plans");
    Map<String, SubscriptionPlan> plans = {};

    try {

      QuerySnapshot querySnapshot = await subscriptionPlanReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.d("Snapshot is not empty");
        for (var planSnapshot in querySnapshot.docs) {
          SubscriptionPlan plan= SubscriptionPlan.fromJSON(planSnapshot.data());
          AppUtilities.logger.d(plan.toString());
          plans[plan.name] = plan;
        }
        AppUtilities.logger.d("${plans.length} plans found");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return plans;
  }

  @override
  Future<List<SubscriptionPlan>> getPlansByType({required SubscriptionLevel level}) async {
    AppUtilities.logger.d("Retrieving Products by type ${level.name}");
    List<SubscriptionPlan> plans = [];

    try {

      QuerySnapshot querySnapshot = await subscriptionPlanReference
          .where(AppFirestoreConstants.level, isEqualTo: level.value)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.d("Snapshot is not empty");
        for (var planSnapshot in querySnapshot.docs) {
          SubscriptionPlan plan= SubscriptionPlan.fromJSON(planSnapshot.data());
          AppUtilities.logger.d(plan.toString());
          plans.add(plan);
        }
        AppUtilities.logger.d("${plans.length} plans found");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return plans;
  }


  @override
  Future<String> insert(SubscriptionPlan plan) async {
    AppUtilities.logger.d("Inserting product ${plan.level?.name}");
    String planId = "";

    try {

      if(plan.id.isNotEmpty) {
        await subscriptionPlanReference.doc(plan.id).set(plan.toJSON());
        planId = plan.id;
      } else {
        DocumentReference documentReference = await subscriptionPlanReference
            .add(plan.toJSON());
        planId = documentReference.id;
        plan.id = planId;
        
      }
      AppUtilities.logger.d("SubscriptionPlan ${plan.level?.name} added with id ${plan.id}");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return planId;

  }


  @override
  Future<bool> remove(AppProduct product) async {
    AppUtilities.logger.d("Removing product ${product.id}");

    try {
      await subscriptionPlanReference.doc(product.id).delete();
      AppUtilities.logger.d("Product ${product.id} removed");
      return true;

    } catch (e) {
      AppUtilities.logger.e(e.toString());      
    }
    return false;
  }


}
