// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

class Order extends Equatable {
  final String orderId;
  final String order;
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
  final String validationCode;
  final String? id;
  final int reference;
  final double? subtotal;
  final double? totalPrice;
  final double? deliveryFee;
  final String? paymentStatus;
  final String? serviceMethod;
  final String? paymentMethod;
  final int? cookingTime;
  final String? restaurantName;
  final List<Map<String, dynamic>>? items;

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
    this.id,
    this.reference = 0,
    this.subtotal,
    this.totalPrice,
    this.deliveryFee,
    this.paymentStatus,
    this.serviceMethod,
    this.paymentMethod,
    this.cookingTime,
    this.restaurantName,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      // Get the reference field
      final ref =
          json['reference'] != null
              ? int.tryParse(json['reference'].toString()) ?? 0
              : 0;

      // Extract restaurant data
      Map<String, dynamic> restaurantData = {};
      if (json['restaurant'] is Map) {
        restaurantData = json['restaurant'] as Map<String, dynamic>;
      }

      // Extract items
      List<Map<String, dynamic>> itemsList = [];
      if (json['items'] is List) {
        itemsList =
            (json['items'] as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
      }

      return Order(
        orderId: _convertToString(json['_id']) ?? '',
        order: _convertToString(json['order']) ?? '',
        validationCode: _convertToString(json['validationCode']) ?? '',
        customerName: json['customerName']?.toString() ?? 'Unknown Customer',
        status: json['status']?.toString().toLowerCase() ?? 'pending',
        pickupLocation:
            json['restaurantName']?.toString() ??
            json['pickupLocation']?.toString() ??
            'Unknown',
        customerPhone: json['phone']?.toString() ?? '',
        deliveryAddress: json['deliveryAddress']?.toString() ?? '',
        deliveryDate:
            json['createdAt'] != null
                ? DateTime.parse(
                  json['createdAt'].toString(),
                ).toLocal().toString()
                : DateTime.now().toString(),
        deliveryMan: json['deliveryMan']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? DateTime.now().toString(),
        updatedAt: json['updatedAt']?.toString() ?? DateTime.now().toString(),
        orderRef: _convertToString(json['orderRef']) ?? ref.toString(),
        reference: ref,
        subtotal:
            json['subtotal'] != null
                ? double.tryParse(json['subtotal'].toString())
                : null,
        totalPrice:
            json['totalPrice'] != null
                ? double.tryParse(json['totalPrice'].toString())
                : null,
        deliveryFee:
            json['deliveryFee'] != null
                ? double.tryParse(json['deliveryFee'].toString())
                : null,
        paymentStatus: json['paymentStatus']?.toString(),
        serviceMethod: json['serviceMethod']?.toString(),
        paymentMethod: json['paymentMethod']?.toString(),
        cookingTime:
            json['cookingTime'] != null
                ? int.tryParse(json['cookingTime'].toString())
                : null,
        restaurantName:
            json['restaurantName']?.toString() ??
            restaurantData['name']?.toString(),
        items: itemsList,
      );
    } catch (e) {
      debugPrint('Error creating Order from JSON: $e');
      debugPrint(
        'Problematic JSON: ${json.toString().substring(0, json.toString().length > 300 ? 300 : json.toString().length)}',
      );

      return Order(
        orderId: json['_id']?.toString() ?? 'error',
        order: 'Error parsing order',
        validationCode: '0000',
        customerName: 'Unknown',
        status: 'unknown',
        pickupLocation: 'Unknown',
        customerPhone: '',
        deliveryAddress: '',
        deliveryDate: DateTime.now().toString(),
        deliveryMan: '',
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString(),
        orderRef: 'ERR',
      );
    }
  }

  static String? _convertToString(dynamic value) {
    if (value == null) return null;
    try {
      return value.toString();
    } catch (e) {
      debugPrint('Error converting value to string: $e');
      return null;
    }
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
    reference,
    subtotal,
    totalPrice,
    deliveryFee,
    paymentStatus,
    serviceMethod,
    paymentMethod,
    cookingTime,
    restaurantName,
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
    int? reference,
    double? subtotal,
    double? totalPrice,
    double? deliveryFee,
    String? paymentStatus,
    String? serviceMethod,
    String? paymentMethod,
    int? cookingTime,
    String? restaurantName,
    List<Map<String, dynamic>>? items,
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
      subtotal: subtotal ?? this.subtotal,
      totalPrice: totalPrice ?? this.totalPrice,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      serviceMethod: serviceMethod ?? this.serviceMethod,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cookingTime: cookingTime ?? this.cookingTime,
      restaurantName: restaurantName ?? this.restaurantName,
      items: items ?? this.items,
    );
  }
}
