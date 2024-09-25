import 'package:enum_to_string/enum_to_string.dart';
import 'package:neom_commons/core/domain/model/price.dart';
import '../../utils/enums/payment_status.dart';

class Payment {

  String id;
  String orderId;
  int createdTime;
  String from; ///FROM EMAIL
  String to; ///TO EMAIL
  Price? price;
  String secretKey;
  PaymentStatus status;

  double tax = 0;

  ///NOT IN USE YET -
  double facilitatorAmount; ///AMOUNT TO FACILITATOR OF EVENTS

  Payment({
    this.id = '',
    this.orderId = '',
    this.createdTime = 0,
    this.from = '',
    this.to = '',
    this.price,
    this.tax = 0,
    this.facilitatorAmount = 0,
    this.secretKey = '',
    this.status = PaymentStatus.pending,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      // 'id': id,
      'orderId': orderId,
      'from': from,
      'createdTime': createdTime,
      'to': to,
      'price': price?.toJSON(),
      'tax': tax,
      'facilitatorAmount': facilitatorAmount,
      'status': status.name,
    };
  }


  Payment.fromJSON(data) :
    id = data["id"] ?? "",
    orderId = data["orderId"] ?? "",
    createdTime =  data["createdTime"] ?? 0,
    from = data["from"] ?? "",
    to = data["to"] ?? "",
    price = data["price"] != null ? Price.fromJSON(data["price"]) : null,
    secretKey = data["secretKey"] ?? "",
    facilitatorAmount = data["facilitatorAmount"] ?? 0,
    tax = data["tax"] ?? 0,
    status = EnumToString.fromString(PaymentStatus.values, data["status"]) ?? PaymentStatus.pending;

}
