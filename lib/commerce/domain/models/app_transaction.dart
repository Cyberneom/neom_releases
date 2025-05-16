import 'package:enum_to_string/enum_to_string.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
// ignore: implementation_imports
import 'package:in_app_purchase_android/src/types/google_play_purchase_details.dart';
// ignore: implementation_imports
import 'package:in_app_purchase_storekit/src/types/app_store_purchase_details.dart';
import 'package:neom_commons/core/domain/model/subscription_plan.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:neom_commons/core/utils/enums/profile_type.dart';
import '../../utils/constants/app_commerce_constants.dart';
import '../../utils/enums/payment_status.dart';
import '../../utils/enums/transaction_type.dart';
import 'app_product.dart';

class AppTransaction {

  String id;
  String description;
  int createdTime;

  TransactionType type;
  double amount;
  AppCurrency currency;
  TransactionStatus status;

  String? orderId; // Opcional: ID de la AppOrder si la transacción es por una compra
  String? senderId; // ID (walletId) de quien envía/origina el débito
  String? recipientId; // ID (walletId) de quien recibe/origina el crédito

  String? secretKey;
  ///VERIFY IF NEEDED
  // double balanceBefore; // Saldo de la billetera afectada ANTES de esta transacción
  // double balanceAfter; // Saldo de la billetera afectada DESPUÉS de esta transacción

  AppTransaction({
    this.amount = 0,
    this.type = TransactionType.purchase,
    this.senderId = AppCommerceConstants.appBank, // Considerar si siempre habrá un senderId
    this.recipientId = AppCommerceConstants.appBank, // Considerar si siempre habrá un recipientId
    this.id = "",
    this.description = "",
    this.createdTime = 0,
    this.orderId, // Es opcional
    this.currency = AppCurrency.appCoin, // Moneda por defecto
    this.status = TransactionStatus.pending, // Estado por defect
    this.secretKey,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': id,
      'description': description,
      'createdTime': createdTime,
      'type': type.name,
      'amount': amount,
      'currency': currency.name,
      'orderId': orderId,
      'status': status.name,
      'senderId': senderId,
      'recipientId': recipientId,
      'secretKey': secretKey,
      // 'balanceBefore': balanceBefore,
      // 'balanceAfter': balanceAfter,
    };
  }

  AppTransaction.fromJSON(data)
      : id = data["id"] ?? "",
        description = data["description"] ?? "",
        createdTime = data["createdTime"] ?? 0,
        type = EnumToString.fromString(TransactionType.values,
            data["type"] ?? TransactionType.purchase.name) ??
            TransactionType.purchase,
        amount = double.parse(data["amount"]?.toString() ?? "0"),
        currency = EnumToString.fromString(
            AppCurrency.values, data["currency"] ?? AppCurrency.appCoin.name) ??
            AppCurrency.appCoin,
        orderId = data["orderId"],
        status = EnumToString.fromString(TransactionStatus.values,
            data["status"] ?? TransactionStatus.pending.name) ??
            TransactionStatus.pending,
        senderId = data["senderId"] ?? "",
        recipientId = data["recipientId"] ?? "",
        secretKey = data["secretKey"] ?? "";
        // balanceBefore = double.parse(data["balanceBefore"]?.toString() ?? "0"),
        // balanceAfter = double.parse(data["balanceAfter"]?.toString() ?? "0");

}
