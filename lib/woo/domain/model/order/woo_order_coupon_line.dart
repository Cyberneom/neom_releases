import 'package:freezed_annotation/freezed_annotation.dart';

import 'woo_order_metadata.dart';

part 'woo_order_coupon_line.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class WooOrderCouponLine {

  int id;
  String code;
  String discount;
  String discountTax;
  List<WooOrderMetaData> metaData;

  WooOrderCouponLine({
    this.id = 0,
    this.code = '',
    this.discount = '',
    this.discountTax = '',
    this.metaData = const [],
  });

  factory WooOrderCouponLine.fromJson(Map<String, dynamic> json) =>
      _$WooOrderCouponLineFromJson(json);

  Map<String, dynamic> toJson() => _$WooOrderCouponLineToJson(this);

}
