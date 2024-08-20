import 'package:freezed_annotation/freezed_annotation.dart';

import 'woo_order_metadata.dart';
import 'woo_order_tax.dart';

part 'woo_order_line_item.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class WooOrderLineItem {

  int id;
  String name;
  int productId;
  int variationId;
  int quantity;
  String taxClass;
  String subtotal;
  String subtotalTax;
  String total;
  String totalTax;
  List<WooOrderTax> taxes;
  List<WooOrderMetaData> metaData;
  String sku;
  int price;
  String? parentName;

  WooOrderLineItem({
    this.id = 0,
    this.name = '',
    this.productId = 0,
    this.variationId = 0,
    this.quantity = 0,
    this.taxClass = '',
    this.subtotal = '',
    this.subtotalTax = '',
    this.total = '',
    this.totalTax = '',
    this.taxes = const [],
    this.metaData = const [],
    this.sku = '',
    this.price = 0,
    this.parentName,
  });

  factory WooOrderLineItem.fromJson(Map<String, dynamic> json) =>
      _$WooOrderLineItemFromJson(json);

  Map<String, dynamic> toJson() => _$WooOrderLineItemToJson(this);

}
