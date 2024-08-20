import 'dart:async';

import 'package:neom_commons/core/utils/enums/product_type.dart';
import '../models/app_sale.dart';


abstract class SalesRepository {

  Future<AppSale> retrieveSales(ProductType productType);
  ///DEPRECATED
  // Future<AppSale> retrieveProductSales();
  // Future<AppSale> retrieveEventSales();
  // Future<AppSale> retrieveBookingSales();
  // Future<AppSale> retrieveReleaseItemSales();
  Future<bool> updateOrderNumber(int newOrderNumber, ProductType productType);
  Future<bool> addOrderId({required String orderId, required ProductType productType});
  Future<bool> removeOrderId({required String orderId, required ProductType productType});


}
