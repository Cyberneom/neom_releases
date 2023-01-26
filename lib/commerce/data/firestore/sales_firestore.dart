import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_commons/core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/enums/sale_type.dart';
import '../../domain/models/app_sale.dart';
import '../../domain/repository/sales_repository.dart';

class SalesFirestore implements SalesRepository {

  final logger = AppUtilities.logger;
  final salesReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.sales);

  @override
  Future<AppSale> retrieveProductSales() async {
    logger.i("Retrieving Sales Info");
    AppSale sales = AppSale();

    try {
      DocumentSnapshot documentSnapshot = await salesReference
          .doc(AppFirestoreConstants.productSales).get();
      if (documentSnapshot.exists) {
        sales = AppSale.fromJSON(documentSnapshot.data());
        logger.i("Sales found with orderNumber ${sales.orderNumber}");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("");
    return sales;
  }


  @override
  Future<AppSale> retrieveEventSales() async {
    logger.i("Retrieving Sales Info");
    AppSale sales = AppSale();

    try {
      DocumentSnapshot documentSnapshot = await salesReference
          .doc(AppFirestoreConstants.eventSales).get();
      if (documentSnapshot.exists) {
        sales = AppSale.fromJSON(documentSnapshot.data());
        logger.i("Sales found with orderNumber ${sales.orderNumber}");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("");
    return sales;
  }


  @override
  Future<bool> updateOrderNumber(int newOrderNumber, SaleType salesType) async {
    logger.d("");

    try {
      String salesToUpdate = "";
      switch(salesType) {
        case SaleType.product:
          salesToUpdate = AppFirestoreConstants.productSales;
          break;
        case SaleType.event:
          salesToUpdate = AppFirestoreConstants.eventSales;
          break;
        case SaleType.booking:
          salesToUpdate = AppFirestoreConstants.bookingSales;
          break;
      }

      DocumentSnapshot documentSnapshot = await salesReference
          .doc(salesToUpdate).get();

      await documentSnapshot.reference.update({AppFirestoreConstants.orderNumber: newOrderNumber});

    } catch (e) {
      logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<AppSale> retrieveBookingSales() async {
    // TODO: implement retrieveBookingSales
    throw UnimplementedError();
  }


  @override
  Future<bool> addOrderId({
    required String orderId, required SaleType saleType}) async {
    logger.d("Order $orderId would be added to Sales for ${saleType.name}");

    try {
      String salesToUpdate = "";
      switch(saleType) {
        case SaleType.product:
        salesToUpdate = AppFirestoreConstants.productSales;
        break;
        case SaleType.event:
        salesToUpdate = AppFirestoreConstants.eventSales;
        break;
        case SaleType.booking:
        salesToUpdate = AppFirestoreConstants.bookingSales;
        break;
      }

      DocumentSnapshot documentSnapshot = await salesReference
          .doc(salesToUpdate).get();


      await documentSnapshot.reference.update({
              AppFirestoreConstants.orderIds: FieldValue.arrayUnion([orderId])
            });
      logger.d("$orderId is now at $salesToUpdate");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> removeOrderId({
    required String orderId,
    required SaleType saleType}) async {
    logger.d("Order $orderId would be removed from Sales of ${saleType.name}");

    try {
      String salesToUpdate = "";
      switch(saleType) {
        case SaleType.product:
          salesToUpdate = AppFirestoreConstants.productSales;
          break;
        case SaleType.event:
          salesToUpdate = AppFirestoreConstants.eventSales;
          break;
        case SaleType.booking:
          salesToUpdate = AppFirestoreConstants.bookingSales;
          break;
      }

      DocumentSnapshot documentSnapshot = await salesReference
          .doc(salesToUpdate).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.orderIds: FieldValue.arrayRemove([orderId])
      });
      logger.d("$orderId was removed from $salesToUpdate");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }


}
