import 'package:enum_to_string/enum_to_string.dart';
import 'package:neom_commons/core/domain/model/price.dart';
import '../../utils/enums/payment_status.dart';
import '../../utils/enums/payment_type.dart';

class Payment {

  String id;
  String orderId;
  String from;
  String to;
  Price price = Price();
  double tax = 0;
  double facilitatorAmount = 0;
  String couponCode = "";
  double discountAmount = 0;
  double referralAmount;
  int referralPercentage;
  double finalAmount = 0;
  PaymentStatus status;
  PaymentType type;


  Payment({
    this.id = "",
    this.orderId = "",
    this.from = "",
    this.to = "",
    this.tax = 0,
    this.facilitatorAmount = 0,
    this.couponCode = "",
    this.discountAmount = 0,
    this.referralAmount = 0,
    this.referralPercentage = 0,
    this.finalAmount = 0,
    this.status = PaymentStatus.pending,
    this.type = PaymentType.notDefined
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      // 'id': id,
      'orderId': orderId,
      'from': from,
      'to': to,
      'price': price.toJSON(),
      'tax': tax,
      'facilitatorAmount': facilitatorAmount,
      'couponCode': couponCode,
      'discountAmount': discountAmount,
      'referralAmount': referralAmount,
      'referralPercentage': referralPercentage,
      'finalAmount': finalAmount,
      'status': status.name,
      'type': type.name,
    };
  }


  Payment.fromJSON(data) :
    id = data["id"] ?? "",
    orderId = data["orderId"] ?? "",
    from = data["from"] ?? "",
    to = data["to"] ?? "",
    price = Price.fromJSON(data["price"]),
    facilitatorAmount = data["facilitatorAmount"] ?? 0,
    couponCode = data["couponCode"] ?? "",
    discountAmount = data["discountAmount"] ?? 0,
    referralAmount = data["referralAmount"] ?? 0,
    referralPercentage = data["referralPercentage"] ?? 0,
    tax = data["tax"] ?? 0,
    finalAmount = data["finalAmount"] ?? 0,
    status = EnumToString.fromString(PaymentStatus.values, data["status"]) ?? PaymentStatus.pending,
    type = EnumToString.fromString(PaymentType.values, data["type"]) ?? PaymentType.notDefined;


}
