// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'woo_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WooOrder _$WooOrderFromJson(Map<String, dynamic> json) => WooOrder(
      id: (json['id'] as num?)?.toInt() ?? 0,
      parentId: (json['parent_id'] as num?)?.toInt() ?? 0,
      number: json['number'] as String? ?? '',
      orderKey: json['order_key'] as String? ?? '',
      createdVia: json['created_via'] as String? ?? '',
      status: json['status'] as String? ?? '',
      dateCreated: json['date_created'] == null
          ? null
          : DateTime.parse(json['date_created'] as String),
      dateCreatedGmt: json['date_created_gmt'] == null
          ? null
          : DateTime.parse(json['date_created_gmt'] as String),
      dateModified: json['date_modified'] == null
          ? null
          : DateTime.parse(json['date_modified'] as String),
      dateModifiedGmt: json['date_modified_gmt'] == null
          ? null
          : DateTime.parse(json['date_modified_gmt'] as String),
      discountTotal: json['discount_total'] as String? ?? '0',
      discountTax: json['discount_tax'] as String? ?? '0',
      shippingTotal: json['shipping_total'] as String? ?? '0',
      shippingTax: json['shipping_tax'] as String? ?? '0',
      cartTax: json['cart_tax'] as String? ?? '0',
      total: json['total'] as String? ?? '0',
      totalTax: json['total_tax'] as String? ?? '0',
      pricesIncludeTax: json['prices_include_tax'] as bool? ?? false,
      customerId: (json['customer_id'] as num?)?.toInt() ?? 0,
      customerIdAddress: json['customer_id_address'] as String? ?? '',
      customerUserAgent: json['customer_user_agent'] as String? ?? '',
      customerNote: json['customer_note'] as String? ?? '',
      billing: json['billing'] == null
          ? null
          : WooBilling.fromJson(json['billing'] as Map<String, dynamic>),
      shipping: json['shipping'] == null
          ? null
          : WooShipping.fromJson(json['shipping'] as Map<String, dynamic>),
      paymentMethod: json['payment_method'] as String? ?? '',
      paymentMethodTitle: json['payment_method_title'] as String? ?? '',
      transactionId: json['transaction_id'] as String? ?? '',
      datePaid: json['date_paid'] == null
          ? null
          : DateTime.parse(json['date_paid'] as String),
      datePaidGmt: json['date_paid_gmt'] == null
          ? null
          : DateTime.parse(json['date_paid_gmt'] as String),
      dateCompleted: json['date_completed'] == null
          ? null
          : DateTime.parse(json['date_completed'] as String),
      dateCompletedGmt: json['date_completed_gmt'] == null
          ? null
          : DateTime.parse(json['date_completed_gmt'] as String),
      cartHash: json['cart_hash'] as String? ?? '',
      metaData: (json['meta_data'] as List<dynamic>?)
              ?.map((e) => WooOrderMetaData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lineItems: (json['line_items'] as List<dynamic>?)
              ?.map((e) => WooOrderLineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      taxLines: (json['tax_lines'] as List<dynamic>?)
              ?.map((e) => WooOrderTaxLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      shippingLines: (json['shipping_lines'] as List<dynamic>?)
              ?.map((e) =>
                  WooOrderShippingLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      feeLines: (json['fee_lines'] as List<dynamic>?)
              ?.map((e) => WooOrderFeeLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      couponLines: (json['coupon_lines'] as List<dynamic>?)
              ?.map(
                  (e) => WooOrderCouponLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      refunds: (json['refunds'] as List<dynamic>?)
              ?.map((e) => WooOrderRefund.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      paymentUrl: json['payment_url'] as String? ?? '',
      setPaid: json['set_paid'] as bool? ?? false,
      isEditable: json['is_editable'] as bool? ?? false,
      needsPayment: json['needs_payment'] as bool? ?? false,
      needsProcessing: json['needs_processing'] as bool? ?? false,
      wpcfDashboard: json['wpcf_dashboard'] as String?,
      currencySymbol: json['currency_symbol'] as String?,
      links: (json['links'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as Map<String, dynamic>),
      ),
    );

Map<String, dynamic> _$WooOrderToJson(WooOrder instance) => <String, dynamic>{
      'id': instance.id,
      'parent_id': instance.parentId,
      'number': instance.number,
      'order_key': instance.orderKey,
      'created_via': instance.createdVia,
      'status': instance.status,
      'date_created': instance.dateCreated?.toIso8601String(),
      'date_created_gmt': instance.dateCreatedGmt?.toIso8601String(),
      'date_modified': instance.dateModified?.toIso8601String(),
      'date_modified_gmt': instance.dateModifiedGmt?.toIso8601String(),
      'discount_total': instance.discountTotal,
      'discount_tax': instance.discountTax,
      'shipping_total': instance.shippingTotal,
      'shipping_tax': instance.shippingTax,
      'cart_tax': instance.cartTax,
      'total': instance.total,
      'total_tax': instance.totalTax,
      'prices_include_tax': instance.pricesIncludeTax,
      'customer_id': instance.customerId,
      'customer_id_address': instance.customerIdAddress,
      'customer_user_agent': instance.customerUserAgent,
      'customer_note': instance.customerNote,
      'billing': instance.billing?.toJson(),
      'shipping': instance.shipping?.toJson(),
      'payment_method': instance.paymentMethod,
      'payment_method_title': instance.paymentMethodTitle,
      'transaction_id': instance.transactionId,
      'date_paid': instance.datePaid?.toIso8601String(),
      'date_paid_gmt': instance.datePaidGmt?.toIso8601String(),
      'date_completed': instance.dateCompleted?.toIso8601String(),
      'date_completed_gmt': instance.dateCompletedGmt?.toIso8601String(),
      'cart_hash': instance.cartHash,
      'meta_data': instance.metaData.map((e) => e.toJson()).toList(),
      'line_items': instance.lineItems.map((e) => e.toJson()).toList(),
      'tax_lines': instance.taxLines.map((e) => e.toJson()).toList(),
      'shipping_lines': instance.shippingLines.map((e) => e.toJson()).toList(),
      'fee_lines': instance.feeLines.map((e) => e.toJson()).toList(),
      'coupon_lines': instance.couponLines.map((e) => e.toJson()).toList(),
      'refunds': instance.refunds.map((e) => e.toJson()).toList(),
      'payment_url': instance.paymentUrl,
      'set_paid': instance.setPaid,
      'is_editable': instance.isEditable,
      'needs_payment': instance.needsPayment,
      'needs_processing': instance.needsProcessing,
      'wpcf_dashboard': instance.wpcfDashboard,
      'currency_symbol': instance.currencySymbol,
      'links': instance.links,
    };
