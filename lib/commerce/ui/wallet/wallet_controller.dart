import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/wallet.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_payment_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:neom_commons/core/utils/enums/product_type.dart';

import '../../data/firestore/order_firestore.dart';
import '../../data/firestore/product_firestore.dart';
import '../../domain/models/app_product.dart';
import '../../domain/models/payment.dart';
import '../../domain/models/purchase_order.dart';
import '../../domain/use_cases/wallet_service.dart';

class WalletController extends GetxController with GetTickerProviderStateMixin implements WalletService  {

  final userController = Get.find<UserController>();

  bool isLoading = true;
  Wallet wallet = Wallet();
  Map<String, PurchaseOrder> orders = {};

  late TabController tabController;

  AppProduct appCoinProduct = AppProduct();
  List<AppProduct> appCoinProducts = [];
  List<AppProduct> appCoinStaticProducts = [];
  double paymentAmount = 0.0;

  Rx<AppCurrency> paymentCurrency = AppCurrency.mxn.obs;

  bool isButtonDisabled = false;
  
  Payment payment = Payment();

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.d("Wallet Controller");
    try {
      wallet = userController.user.wallet;
      tabController = TabController(
        length: 3,
        vsync: this,
      );
      tabController.addListener(_tabChanged);
      payment.from = userController.user.email;
    } catch (e) {
      AppUtilities.logger.e(e);
    }

  }


  @override
  void onReady() async {

    try {
      appCoinProducts = await ProductFirestore().retrieveProductsByType(
          type: ProductType.coin
      );

      appCoinStaticProducts =  await ProductFirestore().retrieveProductsByType(
          type: ProductType.coin
      );
      
      if(appCoinProducts.isNotEmpty) {
        appCoinProducts.sort((a, b) => a.qty.compareTo(b.qty));
        appCoinProduct = appCoinProducts.first;

        paymentCurrency.value = appCoinProduct.salePrice?.currency ?? AppCurrency.mxn;
        paymentAmount = appCoinProduct.salePrice?.amount ?? 0;
      }


      orders = await OrderFirestore().retrieveFromList(userController.user.orderIds);
      List<PurchaseOrder> ordersToSort = orders.values.toList();
      ordersToSort.sort((a, b) => a.createdTime.compareTo(b.createdTime));
      orders.clear();
      for(PurchaseOrder order in ordersToSort.reversed) {
        orders[order.id] = order;
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoading = false;
    update([AppPageIdConstants.walletHistory]);
  }


  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }


  void _tabChanged() {
    if (tabController.indexIsChanging) {
      AppUtilities.logger.d('tabChanged: ${tabController.index}');
    }
  }

  @override
  void changeAppCoinProduct(AppProduct selectedProduct) {
    AppUtilities.logger.d("Changing appCoin Qty to acquire to ${selectedProduct.qty}");

    // newGigCoinProduct = gigCoinProducts.where(
    //         (product) => product.id == newGigCoinProduct.id).first;
    
    try {
      appCoinProduct = selectedProduct;
      if(appCoinProduct.regularPrice!.currency != paymentCurrency.value) {
        // selectedProduct = gigCoinStaticProducts.where(
        //         (product) => product.id == selectedProduct.id).first;
        setActualCurrency(productCurrency: appCoinProduct.regularPrice!.currency);
      } else {
        changePaymentAmount(newAmount: appCoinProduct.salePrice!.amount);
      }
      //gigCoinProduct = selectedProduct;


      appCoinProducts.removeWhere((product) => product.id == appCoinProduct.id);
      appCoinProducts.add(appCoinProduct);
      appCoinProducts.sort((a, b) => a.qty.compareTo(b.qty));
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.walletHistory]);
  }

  @override
  void setActualCurrency({required AppCurrency productCurrency}) {

    try {

      if(productCurrency != paymentCurrency.value) {
        AppUtilities.logger.d("Changing currency of product from ${productCurrency.name} to $paymentCurrency");
        appCoinProduct.regularPrice!.currency = paymentCurrency.value;
        appCoinProduct.salePrice!.currency = paymentCurrency.value;
        changePaymentAmount();
      } else {
        AppUtilities.logger.d("Product Currency is the same one as actual: $paymentCurrency");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.walletHistory]);
  }

  @override
  void changePaymentCurrency({required AppCurrency newCurrency}) {

    try {

      if(newCurrency != paymentCurrency.value) {
        AppUtilities.logger.d("Changing currency from $paymentCurrency to ${newCurrency.name}");
        paymentCurrency.value = newCurrency;
        appCoinProduct.regularPrice!.currency = paymentCurrency.value;
        appCoinProduct.salePrice!.currency = paymentCurrency.value;
        changePaymentAmount();
      } else {
        AppUtilities.logger.d("Payment Currency is the same one: $paymentCurrency");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.walletHistory]);
  }

  @override
  void changePaymentAmount({double newAmount = 0}) {

    bool amountChanged = false;

    double newRegularAmount = 0.0;
    double newSaleAmount = 0.0;

    try {
      if(paymentAmount != newAmount) {
        AppUtilities.logger.d("Changing paymentAmount from $paymentAmount");
        double originalRegularAmount = appCoinStaticProducts.where(
                (product) => product.id == appCoinProduct.id).first.regularPrice!.amount;
        double originalSaleAmount = appCoinStaticProducts.where(
                (product) => product.id == appCoinProduct.id).first.salePrice!.amount;
        AppUtilities.logger.d("Original regular amount $originalRegularAmount & Original sale amount $originalSaleAmount");
        switch(paymentCurrency.value) {
          case (AppCurrency.usd):
            newRegularAmount = originalRegularAmount
                * AppPaymentConstants.mxnToUsd;
            newSaleAmount = originalSaleAmount
                * AppPaymentConstants.mxnToUsd;
            amountChanged = true;
            break;
          case (AppCurrency.eur):
            newRegularAmount = originalRegularAmount
                * AppPaymentConstants.mxnToEur;
            newSaleAmount = originalSaleAmount
                * AppPaymentConstants.mxnToEur;
            amountChanged = true;
            break;
          case (AppCurrency.mxn):
            newRegularAmount = originalRegularAmount;
            newSaleAmount = originalSaleAmount;
            amountChanged = true;
            break;
          case (AppCurrency.gbp):
            newRegularAmount = originalRegularAmount
                * AppPaymentConstants.mxnToGbp;
            newSaleAmount = originalSaleAmount
                * AppPaymentConstants.mxnToGbp;
            amountChanged = true;
            break;
          case (AppCurrency.appCoin):
            break;
        }

        if(amountChanged) {
          newSaleAmount = newSaleAmount.ceilToDouble();
          newRegularAmount = newRegularAmount.ceilToDouble();
          paymentAmount = newSaleAmount;
          AppUtilities.logger.d("Actual regular amount ${appCoinProduct.regularPrice!.amount}"
              " & Actual sale amount ${appCoinProduct.salePrice!.amount}");
          AppUtilities.logger.d("New regular amount $newRegularAmount & New sale amount $newSaleAmount");
          appCoinProduct.regularPrice!.amount = newRegularAmount;
          appCoinProduct.salePrice!.amount = newSaleAmount;
        }
      } else {
        AppUtilities.logger.d("Payment amount is the same one: $paymentAmount");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.walletHistory]);
  }


  @override
  Future<void> payAppProduct(BuildContext context) async {
    AppUtilities.logger.d("Entering payAppProduct Method");

    try {
      appCoinProduct.salePrice!.amount = paymentAmount;
      appCoinProduct.salePrice!.currency = paymentCurrency.value;
      Get.toNamed(AppRouteConstants.orderConfirmation, arguments: [appCoinProduct]);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.walletHistory]);
  }


}
