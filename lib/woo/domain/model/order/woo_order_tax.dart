import 'package:freezed_annotation/freezed_annotation.dart';

import 'woo_order_metadata.dart';

part 'woo_order_tax.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class WooOrderTax {

  int id;
  String rateCode;
  String rateId;
  String label;
  bool compound;
  String taxTotal;
  String shippingTaxTotal;
  List<WooOrderMetaData> metaData;

  WooOrderTax({
    this.id = 0,
    this.rateCode = '',
    this.rateId = '',
    this.label = '',
    this.compound = false,
    this.taxTotal = '',
    this.shippingTaxTotal = '',
    this.metaData = const [],
  });

  factory WooOrderTax.fromJson(Map<String, dynamic> json) =>
      _$WooOrderTaxFromJson(json);

  Map<String, dynamic> toJson() => _$WooOrderTaxToJson(this);
}
