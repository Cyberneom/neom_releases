import 'dart:async';

import 'package:neom_commons/core/utils/enums/sale_type.dart';
import '../models/app_sale.dart';


abstract class SalesRepository {

  Future<AppSale> retrieveProductSales();
  Future<AppSale> retrieveEventSales();
  Future<AppSale> retrieveBookingSales();
  Future<bool> updateOrderNumber(int newOrderNumber, SaleType salesType);
  Future<bool> addOrderId({
    required String orderId,
    required SaleType saleType});
  Future<bool> removeOrderId({
    required String orderId,
    required SaleType saleType});

}
