class StripeProduct {
  String id;
  String name;
  String description;
  bool active;
  String? imageUrl;
  DateTime? created;
  DateTime? updated;

  StripeProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.active,
    this.imageUrl,
    this.created,
    this.updated,
  });

  // Deserialize from JSON
  factory StripeProduct.fromJSON(Map<String, dynamic> data) {
    return StripeProduct(
      id: data['id'],
      name: data['name'],
      description: data['description'] ?? '',
      active: data['active'],
      imageUrl: data['images'] != null && data['images'].isNotEmpty ? data['images'][0] : null,
      created: DateTime.fromMillisecondsSinceEpoch(data['created'] * 1000),
      updated: DateTime.fromMillisecondsSinceEpoch(data['updated'] * 1000),
    );
  }

  // Serialize to JSON
  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'active': active,
      'images': imageUrl != null ? [imageUrl] : [],
      'created': created?.millisecondsSinceEpoch,
      'updated': updated?.millisecondsSinceEpoch,
    };
  }
}
