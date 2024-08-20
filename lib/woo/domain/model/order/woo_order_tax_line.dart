import 'package:freezed_annotation/freezed_annotation.dart';

import 'woo_order_metadata.dart';

part 'woo_order_tax_line.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class WooOrderTaxLine {

  int id;
  String rateCode;
  String rateId;
  String label;
  bool compound;
  String taxTotal;
  String shippingTaxTotal;
  List<WooOrderMetaData> metaData;

  WooOrderTaxLine({
    this.id = 0,
    this.rateCode = '',
    this.rateId = '',
    this.label = '',
    this.compound = false,
    this.taxTotal = '',
    this.shippingTaxTotal = '',
    this.metaData = const [],
  });

  factory WooOrderTaxLine.fromJson(Map<String, dynamic> json) =>
      _$WooOrderTaxLineFromJson(json);

  Map<String, dynamic> toJson() => _$WooOrderTaxLineToJson(this);

}
