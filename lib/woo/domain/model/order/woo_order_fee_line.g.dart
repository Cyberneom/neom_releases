// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'woo_order_fee_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WooOrderFeeLine _$WooOrderFeeLineFromJson(Map<String, dynamic> json) =>
    WooOrderFeeLine(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      taxClass: json['tax_class'] as String? ?? '',
      taxStatus: json['tax_status'] as String? ?? '',
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

Map<String, dynamic> _$WooOrderFeeLineToJson(WooOrderFeeLine instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tax_class': instance.taxClass,
      'tax_status': instance.taxStatus,
      'total': instance.total,
      'tax_total': instance.taxTotal,
      'taxes': instance.taxes.map((e) => e.toJson()).toList(),
      'meta_data': instance.metaData.map((e) => e.toJson()).toList(),
    };
