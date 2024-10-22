class StripePrice {

  String id;
  String currency;
  double unitAmount;
  bool active;
  String product;
  String? interval; // monthly, yearly, etc.
  int? intervalCount;
  DateTime? created;

  StripePrice({
    required this.id,
    required this.currency,
    required this.unitAmount,
    required this.active,
    required this.product,
    this.interval,
    this.intervalCount,
    this.created,
  });

  // Deserialize from JSON
  factory StripePrice.fromJSON(Map<String, dynamic> data) {
    return StripePrice(
      id: data['id'],
      currency: data['currency'],
      unitAmount: data['unit_amount'] / 100.0,  // Stripe stores amounts in cents
      active: data['active'],
      product: data['product'],
      interval: data['recurring']?['interval'],
      intervalCount: data['recurring']?['interval_count'],
      created: DateTime.fromMillisecondsSinceEpoch(data['created'] * 1000),
    );
  }

  // Serialize to JSON
  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'currency': currency,
      'unit_amount': (unitAmount * 100).toInt(),  // Convert back to cents
      'active': active,
      'product': product,
      'recurring': interval != null
          ? {
        'interval': interval,
        'interval_count': intervalCount,
      }
          : null,
      'created': created?.millisecondsSinceEpoch,
    };
  }
}
