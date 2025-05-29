class Order {
  final double restaurantLatitude;
  final double restaurantLongitude;
  final double customerLatitude;
  final double customerLongitude;
  final String id;
  final String status;

  Order({
    required this.id,
    required this.restaurantLatitude,
    required this.restaurantLongitude,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.status,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      restaurantLatitude: json['restaurantLatitude'] as double,
      restaurantLongitude: json['restaurantLongitude'] as double,
      customerLatitude: json['customerLatitude'] as double,
      customerLongitude: json['customerLongitude'] as double,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantLatitude': restaurantLatitude,
      'restaurantLongitude': restaurantLongitude,
      'customerLatitude': customerLatitude,
      'customerLongitude': customerLongitude,
      'status': status,
    };
  }
}
