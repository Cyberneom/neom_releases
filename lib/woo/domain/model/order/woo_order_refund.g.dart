// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'woo_order_refund.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WooOrderRefund _$WooOrderRefundFromJson(Map<String, dynamic> json) =>
    WooOrderRefund(
      id: (json['id'] as num).toInt(),
      reason: json['reason'] as String,
      total: json['total'] as String,
    );

Map<String, dynamic> _$WooOrderRefundToJson(WooOrderRefund instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reason': instance.reason,
      'total': instance.total,
    };
