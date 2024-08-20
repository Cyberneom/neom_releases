// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'woo_order_line_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WooOrderLineItem _$WooOrderLineItemFromJson(Map<String, dynamic> json) =>
    WooOrderLineItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      variationId: (json['variation_id'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      taxClass: json['tax_class'] as String? ?? '',
      subtotal: json['subtotal'] as String? ?? '',
      subtotalTax: json['subtotal_tax'] as String? ?? '',
      total: json['total'] as String? ?? '',
      totalTax: json['total_tax'] as String? ?? '',
      taxes: (json['taxes'] as List<dynamic>?)
              ?.map((e) => WooOrderTax.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      metaData: (json['meta_data'] as List<dynamic>?)
              ?.map((e) => WooOrderMetaData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sku: json['sku'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      parentName: json['parent_name'] as String?,
    );

Map<String, dynamic> _$WooOrderLineItemToJson(WooOrderLineItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'product_id': instance.productId,
      'variation_id': instance.variationId,
      'quantity': instance.quantity,
      'tax_class': instance.taxClass,
      'subtotal': instance.subtotal,
      'subtotal_tax': instance.subtotalTax,
      'total': instance.total,
      'total_tax': instance.totalTax,
      'taxes': instance.taxes.map((e) => e.toJson()).toList(),
      'meta_data': instance.metaData.map((e) => e.toJson()).toList(),
      'sku': instance.sku,
      'price': instance.price,
      'parent_name': instance.parentName,
    };
