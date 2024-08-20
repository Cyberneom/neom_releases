import 'package:freezed_annotation/freezed_annotation.dart';

part 'woo_order_refund.g.dart';

@JsonSerializable()
class WooOrderRefund {

  int id;
  String reason;
  String total;

  WooOrderRefund({
    this.id = 0,
    this.reason = '',
    this.total = '',
  });

  factory WooOrderRefund.fromJson(Map<String, dynamic> json) =>
      _$WooOrderRefundFromJson(json);

  Map<String, dynamic> toJson() => _$WooOrderRefundToJson(this);

}
