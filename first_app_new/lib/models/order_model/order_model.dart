// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

class Order extends Equatable {
  final String orderId;
  final String order;
  final String validationCode;
  final String customerName;
  final String status;
  final String pickupLocation;
  final String customerPhone;
  final String deliveryAddress;
  final String deliveryDate;
  final String deliveryMan;
  final String createdAt;
  final String updatedAt;
  final String orderRef;
  final String? address;
  final String? id;
  final String? restaurantName;
  final String reference;
  final double? restaurantLatitude;
  final double? restaurantLongitude;
  final double? customerLatitude;
  final double? customerLongitude;

  const Order({
    required this.orderId,
    required this.order,
    required this.validationCode,
    required this.customerName,
    required this.status,
    required this.pickupLocation,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.deliveryDate,
    required this.deliveryMan,
    required this.createdAt,
    required this.updatedAt,
    required this.orderRef,
    required this.reference,
    this.address,
    this.id,
    this.restaurantName,
    this.restaurantLatitude,
    this.restaurantLongitude,
    this.customerLatitude,
    this.customerLongitude,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      final restaurantData = json['restaurant'] ?? {};

      String orderNum = '';
      if (json['order'] != null) {
        orderNum = json['order'].toString();
      } else if (json['reference'] != null) {
        orderNum = json['reference'].toString();
      } else if (json['orderRef'] != null) {
        orderNum = json['orderRef'].toString();
      }

      String ref = orderNum;
      if (json['reference'] != null) {
        ref = json['reference'].toString();
      } else if (json['orderRef'] != null) {
        ref = json['orderRef'].toString();
      }

      String validationCode = '';
      if (json['validationCode'] != null) {
        validationCode = json['validationCode'].toString();
      }

      String customerPhone = '';
      if (json['phone'] != null) {
        customerPhone = json['phone'].toString();
      } else if (json['customerPhone'] != null) {
        customerPhone = json['customerPhone'].toString();
      } else if (json['customer'] is Map) {
        final customerData = json['customer'] as Map<String, dynamic>;
        customerPhone = customerData['phone']?.toString() ?? '';
      }

      String deliveryAddress = '';
      if (json['deliveryAddress'] != null) {
        deliveryAddress = json['deliveryAddress'].toString();
      } else if (json['address'] != null) {
        deliveryAddress = json['address'].toString();
      } else if (json['customer'] is Map) {
        final customerData = json['customer'] as Map<String, dynamic>;
        deliveryAddress = customerData['address']?.toString() ?? '';
      }

      // Parse status with proper null handling
      String status = 'pending';
      if (json['status'] != null) {
        status = json['status'].toString().toLowerCase();
      }

      // Parse coordinates
      double? restaurantLat;
      double? restaurantLng;
      double? customerLat;
      double? customerLng;

      if (json['restaurant'] is Map) {
        final restaurant = json['restaurant'] as Map<String, dynamic>;
        restaurantLat = _parseCoordinate(restaurant['latitude']);
        restaurantLng = _parseCoordinate(restaurant['longitude']);
      }

      if (json['customerLatitude'] != null &&
          json['customerLongitude'] != null) {
        customerLat = _parseCoordinate(json['customerLatitude']);
        customerLng = _parseCoordinate(json['customerLongitude']);
      } else if (json['customer'] is Map) {
        final customer = json['customer'] as Map<String, dynamic>;
        customerLat = _parseCoordinate(customer['latitude']);
        customerLng = _parseCoordinate(customer['longitude']);
      }

      // Create order with all available data
      return Order(
        orderId: _convertToString(json['_id']) ?? '',
        order: orderNum,
        validationCode: validationCode,
        customerName:
            json['customerName']?.toString() ??
            (json['customer'] is Map
                ? (json['customer'] as Map<String, dynamic>)['name']?.toString()
                : null) ??
            'Unknown Customer',
        status: status,
        pickupLocation:
            json['restaurantName']?.toString() ??
            json['pickupLocation']?.toString() ??
            restaurantData['address']?.toString() ??
            'Unknown',
        customerPhone: customerPhone,
        deliveryAddress: deliveryAddress,
        deliveryDate:
            json['createdAt'] != null
                ? DateTime.parse(
                  json['createdAt'].toString(),
                ).toLocal().toString()
                : DateTime.now().toString(),
        deliveryMan: json['deliveryMan']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? DateTime.now().toString(),
        updatedAt: json['updatedAt']?.toString() ?? DateTime.now().toString(),
        orderRef: ref,
        reference: ref, // Use the same value as orderRef for reference
        address: json['address']?.toString(),
        id: json['_id']?.toString(),
        restaurantName: restaurantData['name']?.toString(),
        restaurantLatitude: restaurantLat,
        restaurantLongitude: restaurantLng,
        customerLatitude: customerLat,
        customerLongitude: customerLng,
      );
    } catch (e) {
      debugPrint('Error creating Order from JSON: $e');
      debugPrint(
        'Problematic JSON: ${json.toString().substring(0, json.toString().length > 300 ? 300 : json.toString().length)}',
      );

      // Return a fallback order to prevent app crashes
      return const Order(
        orderId: 'error',
        order: 'Error parsing order',
        validationCode: '0000',
        customerName: 'Unknown',
        status: 'unknown',
        pickupLocation: 'Unknown',
        customerPhone: '',
        deliveryAddress: '',
        deliveryDate: '',
        deliveryMan: '',
        createdAt: '',
        updatedAt: '',
        orderRef: '',
        reference: '', // Add reference to fallback
      );
    }
  }

  static String? _convertToString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static double? _parseCoordinate(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
    orderId,
    order,
    validationCode,
    customerName,
    status,
    pickupLocation,
    customerPhone,
    deliveryAddress,
    deliveryDate,
    deliveryMan,
    createdAt,
    updatedAt,
    orderRef,
    address,
    id,
    restaurantName,
    reference,
    restaurantLatitude,
    restaurantLongitude,
    customerLatitude,
    customerLongitude,
  ];

  Order copyWith({
    String? orderId,
    String? order,
    String? validationCode,
    String? customerName,
    String? status,
    String? pickupLocation,
    String? customerPhone,
    String? deliveryAddress,
    String? deliveryDate,
    String? deliveryMan,
    String? createdAt,
    String? updatedAt,
    String? orderRef,
    String? address,
    String? id,
    String? restaurantName,
    String? reference,
    double? restaurantLatitude,
    double? restaurantLongitude,
    double? customerLatitude,
    double? customerLongitude,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      order: order ?? this.order,
      validationCode: validationCode ?? this.validationCode,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryMan: deliveryMan ?? this.deliveryMan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      orderRef: orderRef ?? this.orderRef,
      reference: reference ?? this.reference,
      address: address ?? this.address,
      id: id ?? this.id,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantLatitude: restaurantLatitude ?? this.restaurantLatitude,
      restaurantLongitude: restaurantLongitude ?? this.restaurantLongitude,
      customerLatitude: customerLatitude ?? this.customerLatitude,
      customerLongitude: customerLongitude ?? this.customerLongitude,
    );
  }
}
