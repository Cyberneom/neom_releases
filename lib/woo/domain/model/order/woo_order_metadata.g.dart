// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'woo_order_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WooOrderMetaData _$WooOrderMetaDataFromJson(Map<String, dynamic> json) =>
    WooOrderMetaData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      key: json['key'] as String? ?? '',
      value: json['value'],
    );

Map<String, dynamic> _$WooOrderMetaDataToJson(WooOrderMetaData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'value': instance.value,
    };
