import 'package:enum_to_string/enum_to_string.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import '../../utils/enums/wallet_status.dart';
import 'app_transaction.dart';

class Wallet {

  String id = "";
  double balance = 0.0;
  AppCurrency currency;

  WalletStatus status;
  int createdTime;
  int lastUpdated;
  String? lastTransactionId;

  Wallet({
    this.id = '',
    this.balance = 0.0,
    this.currency = AppCurrency.appCoin, // Valor por defecto
    this.status = WalletStatus.active,   // Valor por defecto
    this.createdTime = 0, // Debería establecerse al crear con DateTime.now().millisecondsSinceEpoch
    this.lastUpdated = 0, // Debería establecerse al crear y actualizar
    this.lastTransactionId, // Opcional
  });

  Map<String, dynamic> toJSON() {
    return {
      'id': id, // Aunque el ID del documento es el mismo, guardarlo puede ser útil.
      'balance': balance,
      'currency': currency.name,
      'status': status.name,
      'createdTime': createdTime,
      'lastUpdated': lastUpdated,
      'lastTransactionId': lastTransactionId,
    };
  }

  Wallet.fromJSON(Map<dynamic, dynamic> data)
      : id = data["id"] ?? "",
        balance = data["balance"]?.toDouble() ?? 0.0,
        currency = EnumToString.fromString(AppCurrency.values, data["currency"]) ?? AppCurrency.appCoin,
        status = EnumToString.fromString(WalletStatus.values, data["status"]) ?? WalletStatus.active,
        createdTime = data["createdTime"]?.toInt() ?? 0,
        lastUpdated = data["lastUpdated"]?.toInt() ?? 0,
        lastTransactionId = data["lastTransactionId"];

}
