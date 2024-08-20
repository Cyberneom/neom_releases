import 'package:freezed_annotation/freezed_annotation.dart';

import 'woo_order_metadata.dart';
import 'woo_order_tax.dart';

part 'woo_order_shipping_line.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class WooOrderShippingLine {

  int id;
  String methodTitle;
  String methodId;
  String total;
  String taxTotal;
  List<WooOrderTax> taxes;
  List<WooOrderMetaData> metaData;

  WooOrderShippingLine({
    this.id = 0,
    this.methodTitle = '',
    this.methodId = '',
    this.total = '',
    this.taxTotal = '',
    this.taxes = const [],
    this.metaData = const [],
  });

  factory WooOrderShippingLine.fromJson(Map<String, dynamic> json) =>
      _$WooOrderShippingLineFromJson(json);

  Map<String, dynamic> toJson() => _$WooOrderShippingLineToJson(this);

}
