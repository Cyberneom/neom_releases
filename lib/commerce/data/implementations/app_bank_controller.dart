import 'dart:async';
import 'dart:io';
import 'dart:ui';


import 'package:neom_commons/core/utils/app_utilities.dart';

import '../../domain/models/app_transaction.dart';
import '../firestore/wallet_firestore.dart';



class AppBankController {

  static final AppBankController _instance = AppBankController._internal();
  factory AppBankController() {
    _instance._init();
    return _instance;
  }

  AppBankController._internal();

  bool _isInitialized = false;

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

  Future<void> processTransaction(AppTransaction transaction) async {
    AppUtilities.logger.t('Processing transaction: ${transaction.id}');

    //TransactionFirestore insert

    //WalletFirestore processTransaction
    WalletFirestore().addTransaction(transaction);

    //TransactionFirestore insertTransaction

  }

}
