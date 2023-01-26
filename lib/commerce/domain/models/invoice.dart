import 'package:neom_commons/core/domain/model/address.dart';
import 'package:neom_commons/core/domain/model/app_user.dart';
import 'payment.dart';

class Invoice {

  String id;
  String description;
  AppUser toUser = AppUser();
  String orderId;
  int createdTime;
  Payment? payment;
  Address? address;

  Invoice({
    this.id = "",
    this.description = "",
    this.orderId = "",
    this.createdTime = 0,
    this.payment,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      //'id': id,
      'description': description,
      'toUser': toUser.toInvoiceJSON(),
      'orderId': orderId,
      'createdTime': createdTime,
      'payment': payment?.toJSON() ?? Payment().toJSON(),
      'address': address?.toJSON() ?? Address().toJSON(),
    };
  }

  Invoice.fromJSON(data) :
    id = data["id"] ?? "",
    description = data["description"] ?? "",
    toUser = AppUser.fromJSON(data["toUser"]),
    orderId = data["orderId"] ?? "",
    createdTime = data["createdTime"] ?? 0,
    payment = Payment.fromJSON(data["payment"]),
    address = Address.fromJSON(data["address"]);

}
