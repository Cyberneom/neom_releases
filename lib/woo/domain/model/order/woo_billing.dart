class WooBilling {

  final String firstName;
  final String lastName;
  final String? company;
  final String address1;
  final String? address2;
  final String city;
  final String? state; //MX AS COUNTRY MX
  final String postcode;
  final String country;
  final String email;
  final String phone;

  WooBilling({
    required this.firstName,
    required this.lastName,
    this.company,
    required this.address1,
    this.address2,
    required this.city,
    this.state,
    required this.postcode,
    required this.country,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toJson() =>
      {
        'first_name': firstName,
        'last_name': lastName,
        'company': company,
        'address_1': address1,
        'address_2': address2,
        'city': city,
        'state': state,
        'postcode': postcode,
        'country': country,
        'email': email,
        'phone': phone,
      };

  // Create a WooBilling object from a Map<String, dynamic>
  factory WooBilling.fromJson(Map<String, dynamic> json) =>
      WooBilling(
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        company: json['company'] as String,
        address1: json['address_1'] as String,
        address2: json['address_2'] as String,
        city: json['city'] as String,
        state: json['state'] as String,
        postcode: json['postcode'] as String,
        country: json['country'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
      );

}
