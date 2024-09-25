import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_commons/core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/enums/product_type.dart';
import '../../domain/models/app_sale.dart';
import '../../domain/repository/sales_repository.dart';

class SalesFirestore implements SalesRepository {

  final salesReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.sales);

  @override
  Future<AppSale> retrieveSales(ProductType productType) async {
    AppUtilities.logger.i("Retrieving Sales Info for ${productType.name}");
    AppSale sales = AppSale();

    try {
      DocumentSnapshot documentSnapshot = await salesReference
          .doc(productType.name).get();
      if (documentSnapshot.exists) {
        sales = AppSale.fromJSON(documentSnapshot.data());
        AppUtilities.logger.i("Sales found with orderNumber ${sales.orderNumber}");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return sales;
  }

  // @override
  // Future<AppSale> retrieveProductSales() async {
  //   AppUtilities.logger.i("Retrieving Sales Info");
  //   AppSale sales = AppSale();
  //
  //   try {
  //     DocumentSnapshot documentSnapshot = await salesReference
  //         .doc(AppFirestoreConstants.productSales).get();
  //     if (documentSnapshot.exists) {
  //       sales = AppSale.fromJSON(documentSnapshot.data());
  //       AppUtilities.logger.i("Sales found with orderNumber ${sales.orderNumber}");
  //     }
  //   } catch (e) {
  //     AppUtilities.logger.e(e.toString());
  //   }
  //
  //   AppUtilities.logger.d("");
  //   return sales;
  // }

  // @override
  // Future<AppSale> retrieveEventSales() async {
  //   AppUtilities.logger.i("Retrieving Sales Info");
  //   AppSale sales = AppSale();
  //
  //   try {
  //     DocumentSnapshot documentSnapshot = await salesReference
  //         .doc(AppFirestoreConstants.eventSales).get();
  //     if (documentSnapshot.exists) {
  //       sales = AppSale.fromJSON(documentSnapshot.data());
  //       AppUtilities.logger.i("Sales found with orderNumber ${sales.orderNumber}");
  //     }
  //   } catch (e) {
  //     AppUtilities.logger.e(e.toString());
  //   }
  //
  //   return sales;
  // }

  // @override
  // Future<AppSale> retrieveReleaseItemSales() async {
  //   AppUtilities.logger.i("Retrieving Sales Info");
  //   AppSale sales = AppSale();
  //
  //   try {
  //     DocumentSnapshot documentSnapshot = await salesReference
  //         .doc(AppFirestoreConstants.releaseItemSales).get();
  //     if (documentSnapshot.exists) {
  //       sales = AppSale.fromJSON(documentSnapshot.data());
  //       AppUtilities.logger.i("Sales found with orderNumber ${sales.orderNumber}");
  //     }
  //   } catch (e) {
  //     AppUtilities.logger.e(e.toString());
  //   }
  //
  //   AppUtilities.logger.d("");
  //   return sales;
  // }


  @override
  Future<bool> updateOrderNumber(int newOrderNumber, ProductType productType) async {
    AppUtilities.logger.d("updateOrderNumber for Sales Type ${productType.name} to $newOrderNumber");

    try {
      DocumentSnapshot documentSnapshot = await salesReference
          .doc(productType.name).get();

      if (documentSnapshot.exists) {
        await documentSnapshot.reference.update({AppFirestoreConstants.orderNumber: newOrderNumber});
      } else {
        await salesReference.doc(productType.name).set({
          AppFirestoreConstants.orderIds: [],
          AppFirestoreConstants.orderNumber: newOrderNumber,
        });
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<bool> addOrderId({
    required String orderId, required ProductType productType}) async {
    AppUtilities.logger.d("Order $orderId would be added to Sales for ${productType.name}");

    try {
      // String salesToUpdate = "";
      // switch(saleType) {
      //   case SaleType.product:
      //     salesToUpdate = AppFirestoreConstants.productSales;
      //     break;
      //   case SaleType.event:
      //     salesToUpdate = AppFirestoreConstants.eventSales;
      //     break;
      //   case SaleType.booking:
      //     salesToUpdate = AppFirestoreConstants.bookingSales;
      //     break;
      //   case SaleType.digitalItem:
      //     salesToUpdate = AppFirestoreConstants.releaseItemSales;
      //     break;
      //   case SaleType.physicalItem:
      //     salesToUpdate = AppFirestoreConstants.releaseItemSales;
      //     break;
      // }

      DocumentSnapshot documentSnapshot = await salesReference
          .doc(productType.name).get();


      await documentSnapshot.reference.update({
        AppFirestoreConstants.orderIds: FieldValue.arrayUnion([orderId])
      });

      AppUtilities.logger.d("$orderId is now at ${productType.name}");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> removeOrderId({
    required String orderId,
    required ProductType productType}) async {
    AppUtilities.logger.d("Order $orderId would be removed from Sales of ${productType.name}");

    try {
      // String salesToUpdate = "";
      // switch(saleType) {
      //   case SaleType.product:
      //     salesToUpdate = AppFirestoreConstants.productSales;
      //     break;
      //   case SaleType.event:
      //     salesToUpdate = AppFirestoreConstants.eventSales;
      //     break;
      //   case SaleType.booking:
      //     salesToUpdate = AppFirestoreConstants.bookingSales;
      //     break;
      //   case SaleType.digitalItem:
      //     salesToUpdate = AppFirestoreConstants.releaseItemSales;
      //     break;
      //   case SaleType.physicalItem:
      //     salesToUpdate = AppFirestoreConstants.releaseItemSales;
      //     break;
      // }

      DocumentSnapshot documentSnapshot = await salesReference
          .doc(productType.name).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.orderIds: FieldValue.arrayRemove([orderId])
      });

      AppUtilities.logger.d("$orderId was removed from ${productType.name}");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


}
