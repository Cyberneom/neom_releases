import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/validator.dart';

import '../../../commerce/domain/models/app_transaction.dart';
import '../../../commerce/domain/models/wallet.dart';
import '../../../commerce/utils/enums/payment_status.dart';
import '../../ui/wallet/wallet_controller.dart';
import '../transaction_firestore.dart';
import '../wallet_firestore.dart';

class AppBankController {

  static final AppBankController _instance = AppBankController._internal();

  factory AppBankController() {
    _instance._init();
    return _instance;
  }

  AppBankController._internal();
  bool _isInitialized = false;

  TransactionStatus transactiontStatus = TransactionStatus.pending;
  Wallet wallet = Wallet();

  /// Inicialización manual para controlar mejor el ciclo de vida
  Future<void> _init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    AppUtilities.logger.t('AppBankController Controller Initialization');

    try {

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  Future<bool> processTransaction(AppTransaction transaction) async {
    AppUtilities.logger.t('Processing transaction: ${transaction.id}');

    //TransactionFirestore insert
    // transactiontStatus = TransactionStatus.processing;

    try {
      ///Validate and get coins from user wallet
      if((wallet.balance >= (transaction?.amount ?? 0))) {

        if(Validator.isEmail(transaction.recipientId ?? '')) {
          ///Add coins to host wallet
          // await payToUserWithCoins();
        } else {
          ///Add coins to bank in case there is no payment.to
          //Verify Transaction created has appBank as recipientId
          // await payToBank();
        }
        // transactiontStatus = TransactionStatus.completed;

        //WalletFirestore processTransaction
        WalletFirestore().addTransaction(transaction);

        //TransactionFirestore insertTransaction


      } else {
        // transactiontStatus = TransactionStatus.failed;
        // errorMsg = MessageTranslationConstants.notEnoughFundsMsg.tr;
        AppUtilities.logger.e(MessageTranslationConstants.notEnoughFundsMsg.tr);
        return false;
      }

      // await TransactionFirestore().updateStatus(transaction.id, transactiontStatus);

      // if(transactiontStatus == TransactionStatus.completed) {
      //   await handleProcessedPayment();
      // } else {
      //   Get.back();
      //   AppUtilities.showSnackBar(
      //     title: MessageTranslationConstants.errorProcessingPayment.tr,
      //     message: errorMsg.tr,
      //   );
      //   return false;
      // }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }


    return true;
  }

  Future<bool> addCoinsToWallet(String walletId, {double amount = 0}) async {
    AppUtilities.logger.t('Adding coins to wallet: $walletId');
    int coinsQty = 0;

    AppTransaction transaction = AppTransaction(
      id: walletId,
      amount: amount,
      recipientId: walletId,
      status: TransactionStatus.pending,
    );

    try {
      try {
        transaction.amount = Get.find<WalletController>().appCoinProduct.value.qty.toDouble();
        AppUtilities.logger.d('$coinsQty from found WalletController');
      } catch(e) {
        transaction.amount = Get.put(WalletController()).appCoinProduct.value.qty.toDouble();
        AppUtilities.logger.d('$coinsQty from initiated WalletController');
      }

      if(transaction.amount > 0) {
        await WalletFirestore().addTransaction(transaction);
      } else {
        return false;
      }

      await TransactionFirestore().insert(transaction);

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    return true;
  }

}
