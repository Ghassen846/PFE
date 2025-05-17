class DashbordModel {
  String id;
  String deliveryMan;
  int ratings;
  int totalDeliveries;
  int totalCanceled;
  int pendingDeliveries;
  String totalCollected;
  int completedDeliveries;

  DashbordModel({
    this.id = '',
    required this.deliveryMan,
    required this.ratings,
    required this.totalDeliveries,
    required this.totalCanceled,
    required this.pendingDeliveries,
    required this.totalCollected,
    required this.completedDeliveries,
  });

  // Factory constructor to create an instance from a JSON map
  factory DashbordModel.fromJson(Map<String, dynamic> json) {
    return DashbordModel(
      id: json['_id'] as String,
      deliveryMan: json['deliveryMan'] as String,
      ratings: json['rattings'] as int,
      totalDeliveries: json['totalDeliveries'] as int,
      totalCanceled: json['totalCanceled'] as int,
      pendingDeliveries: json['pendingDeliveries'] as int,
      totalCollected: json['totalCollected'] as String,
      completedDeliveries: json['completedDeliveries'] as int,
    );
  }

  // Method to convert an instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'deliveryMan': deliveryMan,
      'rattings': ratings,
      'totalDeliveries': totalDeliveries,
      'totalCanceled': totalCanceled,
      'pendingDeliveries': pendingDeliveries,
      'totalCollected': totalCollected,
      'completedDeliveries': completedDeliveries,
    };
  }
}
