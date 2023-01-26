import 'package:enum_to_string/enum_to_string.dart';

import 'package:neom_commons/core/domain/model/booking.dart';
import 'package:neom_commons/core/domain/model/event.dart';
import 'package:neom_commons/core/utils/enums/sale_type.dart';
import 'app_product.dart';

class PurchaseOrder {

  String id;
  String description;
  SaleType saleType;
  int createdTime;
  List<String>? paymentIds;
  List<String>? invoiceIds;

  AppProduct? product;
  Booking? booking;
  Event? event;

  PurchaseOrder({
    this.id = "",
    this.description = "",
    this.saleType = SaleType.product,
    this.createdTime = 0,
    this.paymentIds,
    this.invoiceIds,
    this.product,
    this.booking,
    this.event
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      //'id': id
      'description': description,
      'saleType': saleType.name,
      'createdTime': createdTime,
      'paymentIds': paymentIds,
      'invoiceIds': invoiceIds,
      'product': product?.toJSON(),
      'booking': booking?.toJSON(),
      'event': event?.toJSON(),

    };
  }

  PurchaseOrder.fromJSON(data) :
    id = data["id"] ?? "",
    description = data["description"] ?? "",
    saleType = EnumToString.fromString(SaleType.values, data["saleType"]) ?? SaleType.product,
    createdTime = data["createdTime"] ?? 0,
    paymentIds = data["paymentIds"]?.cast<String>() ?? [],
    invoiceIds = data["invoiceIds"]?.cast<String>() ?? [],
    product = AppProduct.fromJSON(data["product"] ?? {}),
    booking = Booking.fromJSON(data["booking"] ?? {}),
    event = Event.fromJSON(data["event"] ?? {});

}
