class ShippingAddress {
  String firstName;
  String lastName;
  String address1;
  String city;
  String state;
  String postcode;
  String country;
  String email;
  String phone;

  ShippingAddress({
    required this.firstName,
    required this.lastName,
    required this.address1,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    required this.email,
    required this.phone,
  });

  // Convert a ShippingAddress object to a JSON map
  Map<String, dynamic> toJSON() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'address_1': address1,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      'email': email,
      'phone': phone,
    };
  }

  // Create a ShippingAddress object from a JSON map
  factory ShippingAddress.fromJSON(Map<String, dynamic> json) {
    return ShippingAddress(
      firstName: json['first_name'],
      lastName: json['last_name'],
      address1: json['address_1'],
      city: json['city'],
      state: json['state'],
      postcode: json['postcode'],
      country: json['country'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}
