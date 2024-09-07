// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'woo_order_shipping_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WooOrderShippingLine _$WooOrderShippingLineFromJson(
        Map<String, dynamic> json) =>
    WooOrderShippingLine(
      id: (json['id'] as num?)?.toInt() ?? 0,
      methodTitle: json['method_title'] as String? ?? '',
      methodId: json['method_id'] as String? ?? '',
      total: json['total'] as String? ?? '',
      taxTotal: json['tax_total'] as String? ?? '',
      taxes: (json['taxes'] as List<dynamic>?)
              ?.map((e) => WooOrderTax.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      metaData: (json['meta_data'] as List<dynamic>?)
              ?.map((e) => WooOrderMetaData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WooOrderShippingLineToJson(
        WooOrderShippingLine instance) =>
    <String, dynamic>{
      'id': instance.id,
      'method_title': instance.methodTitle,
      'method_id': instance.methodId,
      'total': instance.total,
      'tax_total': instance.taxTotal,
      'taxes': instance.taxes.map((e) => e.toJson()).toList(),
      'meta_data': instance.metaData.map((e) => e.toJson()).toList(),
    };
