import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_payment_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:neom_commons/core/utils/enums/product_type.dart';

import '../../../commerce/data/firestore/order_firestore.dart';
import '../../../commerce/data/firestore/product_firestore.dart';
import '../../../commerce/domain/models/app_order.dart';
import '../../../commerce/domain/models/app_product.dart';
import '../../../commerce/domain/models/app_transaction.dart';
import '../../../commerce/domain/models/wallet.dart';
import '../../../commerce/domain/use_cases/wallet_service.dart';
import '../../data/wallet_firestore.dart';

class WalletController extends GetxController implements WalletService  {

  final userController = Get.find<UserController>();

  RxBool isLoading = true.obs;

  Wallet? wallet;
  List<AppTransaction> transactions = [];
  Map<String, AppOrder> orders = {};

  /// late TabController tabController;

  Rx<AppProduct> appCoinProduct = AppProduct().obs;
  List<AppProduct> appCoinProducts = [];
  List<AppProduct> appCoinStaticProducts = [];
  RxDouble paymentAmount = 0.0.obs;

  Rx<AppCurrency> paymentCurrency = AppCurrency.mxn.obs;

  RxBool isButtonDisabled = false.obs;
  bool sellAppCoins = false;
  
  AppTransaction? transaction;

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.d("Wallet Controller");
    try {
      loadWalletInfo();
      // loadOrders();
      /// tabController = TabController(
      //   length: 3,
      //   vsync: this,
      // );
      // tabController.addListener(_tabChanged);
      transaction?.senderId = userController.user.email;
    } catch (e) {
      AppUtilities.logger.e(e);
    }

  }


  @override
  void onReady() async {
    try {
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  Future<void> loadWalletInfo() async {
    try {
      await loadWallet();
      await loadOrders();
      // await loadCoinProducts();

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.walletHistory]);
  }
  Future<void> loadWallet() async {
    //load WalletFirestore
    wallet = await WalletFirestore().getOrCreate(userController.user.email);
    //load TransactionsFirestore
  }

  Future<void> loadOrders() async {
    orders = await OrderFirestore().retrieveFromList(userController.user.orderIds);
    List<AppOrder> ordersToSort = orders.values.toList();
    ordersToSort.sort((a, b) => a.createdTime.compareTo(b.createdTime));
    orders.clear();
    for(AppOrder order in ordersToSort.reversed) {
      orders[order.id] = order;
    }
  }

  Future<void> loadCoinProducts() async {
    appCoinProducts = await ProductFirestore()
        .retrieveProductsByType(type: ProductType.appCoin);

    appCoinStaticProducts =  await ProductFirestore()
        .retrieveProductsByType(type: ProductType.appCoin);

    if(appCoinProducts.isNotEmpty) {
      appCoinProducts.sort((a, b) => a.qty.compareTo(b.qty));
      appCoinProduct.value = appCoinProducts.first;

      paymentCurrency.value = appCoinProduct.value.salePrice?.currency ?? AppCurrency.mxn;
      paymentAmount.value = appCoinProduct.value.salePrice?.amount ?? 0;
    }
  }

  @override
  void dispose() {
    /// tabController.dispose();
    super.dispose();
  }


  /// void _tabChanged() {
  //   if (tabController.indexIsChanging) {
  //     AppUtilities.logger.d('tabChanged: ${tabController.index}');
  //   }
  // }

  @override
  void changeAppCoinProduct(AppProduct selectedProduct) {
    AppUtilities.logger.d("Changing appCoin Qty to acquire to ${selectedProduct.qty}");

    // newGigCoinProduct = gigCoinProducts.where(
    //         (product) => product.id == newGigCoinProduct.id).first;
    
    try {
      appCoinProduct.value = selectedProduct;
      if(appCoinProduct.value.regularPrice!.currency != paymentCurrency.value) {
        // selectedProduct = gigCoinStaticProducts.where(
        //         (product) => product.id == selectedProduct.id).first;
        setActualCurrency(productCurrency: appCoinProduct.value.regularPrice!.currency);
      } else {
        changePaymentAmount(newAmount: appCoinProduct.value.salePrice!.amount);
      }
      //gigCoinProduct = selectedProduct;


      appCoinProducts.removeWhere((product) => product.id == appCoinProduct.value.id);
      appCoinProducts.add(appCoinProduct.value);
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
        appCoinProduct.value.regularPrice!.currency = paymentCurrency.value;
        appCoinProduct.value.salePrice!.currency = paymentCurrency.value;
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
        appCoinProduct.value.regularPrice!.currency = paymentCurrency.value;
        appCoinProduct.value.salePrice!.currency = paymentCurrency.value;
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
      if(paymentAmount.value != newAmount) {
        AppUtilities.logger.d("Changing paymentAmount from $paymentAmount");
        double originalRegularAmount = appCoinStaticProducts.where(
                (product) => product.id == appCoinProduct.value.id).first.regularPrice!.amount;
        double originalSaleAmount = appCoinStaticProducts.where(
                (product) => product.id == appCoinProduct.value.id).first.salePrice!.amount;
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
          paymentAmount.value = newSaleAmount;
          AppUtilities.logger.d("Actual regular amount ${appCoinProduct.value.regularPrice!.amount}"
              " & Actual sale amount ${appCoinProduct.value.salePrice!.amount}");
          AppUtilities.logger.d("New regular amount $newRegularAmount & New sale amount $newSaleAmount");
          appCoinProduct.value.regularPrice!.amount = newRegularAmount;
          appCoinProduct.value.salePrice!.amount = newSaleAmount;
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
      appCoinProduct.value.salePrice!.amount = paymentAmount.value;
      appCoinProduct.value.salePrice!.currency = paymentCurrency.value;
      Get.toNamed(AppRouteConstants.orderConfirmation, arguments: [appCoinProduct.value]);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.walletHistory]);
  }


}
