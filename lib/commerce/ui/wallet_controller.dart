import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/wallet.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_payment_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';

import '../data/firestore/order_firestore.dart';
import '../data/firestore/product_firestore.dart';
import '../domain/models/app_product.dart';
import '../domain/models/payment.dart';
import '../domain/models/purchase_order.dart';
import '../domain/use_cases/wallet_service.dart';
import '../utils/enums/payment_type.dart';
import '../utils/enums/product_type.dart';

class WalletController extends GetxController with GetTickerProviderStateMixin implements WalletService  {

  final logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final Rx<AppProfile> _profile = AppProfile().obs;
  AppProfile get profile => _profile.value;
  set profile(AppProfile profile) => _profile.value = profile;

  final Rx<Wallet> _wallet = Wallet().obs;
  Wallet get wallet => _wallet.value;
  set wallet(Wallet wallet) => _wallet.value = wallet;

  final RxMap<String, PurchaseOrder> _orders = <String, PurchaseOrder>{}.obs;
  Map<String, PurchaseOrder> get orders => _orders;
  set orders(Map<String, PurchaseOrder> orders) => _orders.value = orders;

  late TabController tabController;

  final Rx<AppProduct> _appCoinProduct = AppProduct().obs;
  AppProduct get appCoinProduct => _appCoinProduct.value;
  set appCoinProduct(AppProduct appCoinProduct) => _appCoinProduct.value = appCoinProduct;

  final RxList<AppProduct> _appCoinProducts = <AppProduct>[].obs;
  List<AppProduct> get appCoinProducts =>  _appCoinProducts;
  set appCoinProducts(List<AppProduct> appCoinProducts) => _appCoinProducts.value = appCoinProducts;

  final RxList<AppProduct> _appCoinStaticProducts = <AppProduct>[].obs;
  List<AppProduct> get appCoinStaticProducts =>  _appCoinStaticProducts;
  set appCoinStaticProducts(List<AppProduct> appCoinStaticProducts) => _appCoinStaticProducts.value = appCoinStaticProducts;
  
  final RxDouble _paymentAmount = 0.0.obs;
  double get paymentAmount => _paymentAmount.value;
  set paymentAmount(double paymentAmount) => _paymentAmount.value = paymentAmount;

  final Rx<AppCurrency> _paymentCurrency = AppCurrency.mxn.obs;
  AppCurrency get paymentCurrency => _paymentCurrency.value;
  set paymentCurrency(AppCurrency paymentCurrency) => _paymentCurrency.value = paymentCurrency;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  Payment payment = Payment();


  @override
  void onInit() async {
    super.onInit();
    logger.d("Wallet Controller");
    try {
      profile = userController.profile;
      wallet = userController.user!.wallet;
      tabController = TabController(
        length: 3,
        vsync: this,
      );
      tabController.addListener(_tabChanged);
      payment.type = PaymentType.product;
      payment.from = profile.id;
    } catch (e) {
      logger.e(e);
    }

  }


  @override
  void onReady() async {

    try {
      appCoinProducts = await ProductFirestore().retrieveProductsByType(
          type: ProductType.coins
      );

      appCoinStaticProducts =  await ProductFirestore().retrieveProductsByType(
          type: ProductType.coins
      );
      
      if(appCoinProducts.isNotEmpty) {
        appCoinProducts.sort((a, b) => a.qty.compareTo(b.qty));
        appCoinProduct = appCoinProducts.first;

        paymentCurrency = appCoinProduct.salePrice?.currency ?? AppCurrency.mxn;
        paymentAmount = appCoinProduct.salePrice?.amount ?? 0;
      }


      orders = await OrderFirestore().retrieveFromList(userController.user!.orderIds);
      List<PurchaseOrder> ordersToSort = orders.values.toList();
      ordersToSort.sort((a, b) => a.createdTime.compareTo(b.createdTime));
      orders.clear();
      for(PurchaseOrder order in ordersToSort.reversed) {
        orders[order.id] = order;
      }

    } catch (e) {
      logger.e(e.toString());
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
      logger.d('tabChanged: ${tabController.index}');
    }
  }

  @override
  void changeAppCoinProduct(AppProduct selectedProduct) {
    logger.d("Changing appCoin Qty to acquire to ${selectedProduct.qty}");

    // newGigCoinProduct = gigCoinProducts.where(
    //         (product) => product.id == newGigCoinProduct.id).first;
    
    try {
      appCoinProduct = selectedProduct;
      if(appCoinProduct.regularPrice!.currency != paymentCurrency) {
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
      logger.e(e.toString());
    }

    update([AppPageIdConstants.walletHistory]);
  }

  @override
  void setActualCurrency({required AppCurrency productCurrency}) {

    try {

      if(productCurrency != paymentCurrency) {
        logger.d("Changing currency of product from ${productCurrency.name} to $paymentCurrency");
        appCoinProduct.regularPrice!.currency = paymentCurrency;
        appCoinProduct.salePrice!.currency = paymentCurrency;
        changePaymentAmount();
      } else {
        logger.d("Product Currency is the same one as actual: $paymentCurrency");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.walletHistory]);
  }

  @override
  void changePaymentCurrency({required AppCurrency newCurrency}) {

    try {

      if(newCurrency != paymentCurrency) {
        logger.d("Changing currency from $paymentCurrency to ${newCurrency.name}");
        paymentCurrency = newCurrency;
        appCoinProduct.regularPrice!.currency = paymentCurrency;
        appCoinProduct.salePrice!.currency = paymentCurrency;
        changePaymentAmount();
      } else {
        logger.d("Payment Currency is the same one: $paymentCurrency");
      }
    } catch (e) {
      logger.e(e.toString());
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
        logger.d("Changing paymentAmount from $paymentAmount");
        double originalRegularAmount = appCoinStaticProducts.where(
                (product) => product.id == appCoinProduct.id).first.regularPrice!.amount;
        double originalSaleAmount = appCoinStaticProducts.where(
                (product) => product.id == appCoinProduct.id).first.salePrice!.amount;
        logger.d("Original regular amount $originalRegularAmount & Original sale amount $originalSaleAmount");
        switch(paymentCurrency) {
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
          logger.d("Actual regular amount ${appCoinProduct.regularPrice!.amount}"
              " & Actual sale amount ${appCoinProduct.salePrice!.amount}");
          logger.d("New regular amount $newRegularAmount & New sale amount $newSaleAmount");
          appCoinProduct.regularPrice!.amount = newRegularAmount;
          appCoinProduct.salePrice!.amount = newSaleAmount;
        }
      } else {
        logger.d("Payment amount is the same one: $paymentAmount");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.walletHistory]);
  }


  @override
  Future<void> payAppProduct(BuildContext context) async {
    logger.d("Entering payAppProduct Method");

    try {
      appCoinProduct.salePrice!.amount = paymentAmount;
      appCoinProduct.salePrice!.currency = paymentCurrency;
      Get.offAndToNamed(AppRouteConstants.orderConfirmation, arguments: [appCoinProduct]);
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.walletHistory]);
  }


}
