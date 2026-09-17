class DeliveryAddress {
  const DeliveryAddress({
    required this.name,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
  });

  final String name;
  final String phone;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;

  String get formattedAddress {
    return '$addressLine, $city, $state - $pincode';
  }
}
