// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'woo_order_coupon_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WooOrderCouponLine _$WooOrderCouponLineFromJson(Map<String, dynamic> json) =>
    WooOrderCouponLine(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      discount: json['discount'] as String,
      discountTax: json['discount_tax'] as String,
      metaData: (json['meta_data'] as List<dynamic>)
          .map((e) => WooOrderMetaData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WooOrderCouponLineToJson(WooOrderCouponLine instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'discount': instance.discount,
      'discount_tax': instance.discountTax,
      'meta_data': instance.metaData.map((e) => e.toJson()).toList(),
    };
