// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

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
  final String? address; // Make optional
  final String? id; // Make optional

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
    this.address, // Optional
    this.id, // Optional
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['_id'],
      order: json['order'],
      validationCode: json['validationCode'],
      customerName: json['customerName'],
      status: json['status'],
      pickupLocation: json['pickupLocation'],
      customerPhone: json['customerPhone'],
      deliveryAddress: json['deliveryAddress'],
      deliveryDate: json['deliveryDate'],
      deliveryMan: json['deliveryMan'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      orderRef: json['orderRef'],
    );
  }

  factory Order.fromJson1(Map<String, dynamic> json) {
    final deliveryOrderJson = json['deliveryOrder'];
    return Order(
      orderId: deliveryOrderJson['_id'],
      order: deliveryOrderJson['order'],
      validationCode: deliveryOrderJson['validationCode'],
      customerName: deliveryOrderJson['customerName'],
      status: deliveryOrderJson['status'],
      pickupLocation: deliveryOrderJson['pickupLocation'],
      customerPhone: deliveryOrderJson['customerPhone'],
      deliveryAddress: deliveryOrderJson['deliveryAddress'],
      deliveryDate: deliveryOrderJson['deliveryDate'],
      deliveryMan: deliveryOrderJson['deliveryMan'],
      createdAt: deliveryOrderJson['createdAt'],
      updatedAt: deliveryOrderJson['updatedAt'],
      orderRef: deliveryOrderJson['orderRef'],
    );
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
  ];

  Order copyWith({
    String? orderId,
    String? orderRef,
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
    );
  }
}
