import 'package:freezed_annotation/freezed_annotation.dart';

import 'woo_order_metadata.dart';
import 'woo_order_tax.dart';

part 'woo_order_fee_line.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class WooOrderFeeLine {

  int id;
  String name;
  String taxClass;
  String taxStatus;
  String total;
  String taxTotal;
  List<WooOrderTax> taxes;
  List<WooOrderMetaData> metaData;

  WooOrderFeeLine({
    this.id = 0,
    this.name = '',
    this.taxClass = '',
    this.taxStatus = '',
    this.total = '',
    this.taxTotal = '',
    this.taxes = const [],
    this.metaData = const [],
  });

  factory WooOrderFeeLine.fromJson(Map<String, dynamic> json) =>
      _$WooOrderFeeLineFromJson(json);

  Map<String, dynamic> toJson() => _$WooOrderFeeLineToJson(this);

}
