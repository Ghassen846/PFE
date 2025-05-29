import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:first_app_new/services/order_service.dart';
import 'package:first_app_new/services/user_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/order_model/order_model.dart';
import '../../models/dashbord_model/dashbord_model.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  static HomeBloc get(BuildContext context) => BlocProvider.of(context);
  static const _secureStorage = FlutterSecureStorage();

  HomeBloc() : super(const HomeState()) {
    on<HomeSignInEvent>(signInEvent);
    on<HomeInitialEvent>(mapHomeInitialEvent);
    on<HomeNavigateEvent>(mapHomeNavigateEvent);
    on<HomeToggleThemeEvent>(toggleThemeEvent);
    on<HomeConnectivityEvent>(toggleConnectivityEvent);
    on<HomeCheckSaissionEvent>(checkSaissionEvent);
    on<HomeAddOrderEvent>(addOrderEvent);
    on<HomeChangeOrderStatusEvent>(changeOrderStatusEvent);
    on<HomeNewOrderEvent>(homeNewOrderEvent);
    on<HomeChangeTabScreenEvent>(homeChangeTabScreenEvent);
    on<HomeUploadImageEvent>(uploadImageEvent);
    on<HomeChangeLanguage>(changeLanguage);
    on<HomeFetchDashbordData>(onFetchDashbordData);
    on<HomeChangeIndexPage>(onChangeIndexPage);
  }

  Future<void> mapHomeInitialEvent(
    HomeInitialEvent event,
    Emitter<HomeState> emit,
  ) async {
    log('Starting mapHomeInitialEvent - setting loading state');
    emit(state.copyWith(status: StateStatus.loading));

    try {
      log('Fetching orders in mapHomeInitialEvent');
      List<Order> orderList = await OrderService().getOrders();
      log('Orders fetched successfully: ${orderList.length} orders');
      emit(state.copyWith(orderList: orderList, status: StateStatus.loaded));
      log('State updated to loaded with orders');
    } catch (e) {
      log('Failed to fetch orders in mapHomeInitialEvent: $e');
      emit(
        state.copyWith(
          status: StateStatus.error,
          error: 'Failed to fetch orders: $e',
        ),
      );
    }
  }

  FutureOr<void> mapHomeNavigateEvent(
    HomeNavigateEvent event,
    Emitter<HomeState> emit,
  ) {
    if (event.currentIndex != 0) {
      emit(
        state.copyWith(
          navigatorIndex: event.currentIndex,
          status: StateStatus.loaded,
        ),
      );
    } else {
      emit(state.copyWith(navigatorIndex: event.currentIndex));
    }
  }

  FutureOr<void> signInEvent(
    HomeSignInEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(
      state.copyWith(status: StateStatus.loading, error: null),
    ); // Reset error state
    try {
      final String id = event.id;
      final String token = event.token;
      final String username = event.username;

      if (token.isEmpty) {
        log('Sign-in failed: Empty token provided');
        // Try using a simpler approach to update the state
        emit(
          state.copyWith(status: StateStatus.error, error: 'No token provided'),
        );
        return;
      }

      // Save session data
      await saveSessionData(id, token, username);
      log("id: $id + token: $token + username:$username");

      // Fetch orders
      try {
        List<Order> orderList = await OrderService().getOrders();
        emit(
          state.copyWith(
            status: StateStatus.loaded,
            id: id,
            token: token,
            username: username,
            orderList: orderList,
          ),
        );
      } catch (e) {
        log('Failed to fetch orders: $e');
        if (e.toString().contains('401')) {
          log('Unauthorized: Invalid or expired token');
          await deleteSessionData();
          emit(
            state.copyWith(
              status: StateStatus.error,
              error: 'Token expired or invalid',
            ),
          );
        } else if (e is SocketException ||
            e.toString().contains('SocketException')) {
          emit(
            state.copyWith(
              status: StateStatus.error,
              error: 'Network error: Cannot connect to server',
            ),
          );
        } else if (e is TimeoutException) {
          emit(
            state.copyWith(
              status: StateStatus.error,
              error: 'Network error: Connection timed out',
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: StateStatus.error,
              error: 'Failed to fetch orders: $e',
            ),
          );
        }
      }
    } catch (e) {
      log('Sign-in error: $e');
      // Simplify error handling
      emit(state.copyWith(status: StateStatus.error, error: 'Sign-in failed'));
    }
  }

  Future<void> saveSessionData(String id, String token, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryDate = DateTime.now().add(const Duration(hours: 24));

      // Save to SharedPreferences
      await prefs.setString('user_id', id);
      await prefs.setString('token', token);
      await prefs.setString('username', username);
      await prefs.setString('expiry_date', expiryDate.toIso8601String());

      // Save to FlutterSecureStorage
      await _secureStorage.write(key: 'token', value: token);

      log(
        'Session data saved: id=$id, username=$username, expiry=${expiryDate.toIso8601String()}',
      );
    } catch (e) {
      log('Error saving session data: $e');
      throw Exception('Failed to save session data: $e');
    }
  }

  Future<Map<String, String>> getSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    String id = prefs.getString('user_id') ?? '';
    String token = prefs.getString('token') ?? '';
    String username = prefs.getString('username') ?? '';
    String expiryDateString = prefs.getString('expiry_date') ?? '';
    DateTime? expiryDate;
    bool isExpired = true;

    if (expiryDateString.isNotEmpty) {
      try {
        expiryDate = DateTime.parse(expiryDateString);
        isExpired = DateTime.now().isAfter(expiryDate);
      } catch (e) {
        log(
          'Error parsing expiry_date: $e, expiryDateString=$expiryDateString',
        );
        expiryDate = null;
        isExpired = true;
      }
    }

    log(
      'Session data retrieved: id=$id, username=$username, token=${token.isEmpty ? 'empty' : 'present'}, expiry=$expiryDateString, isExpired=$isExpired',
    );

    return {
      'id': id,
      'token': token,
      'username': username,
      'expiryDate': expiryDateString,
      'isExpired': isExpired ? 'true' : 'false',
    };
  }

  Future<void> deleteSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('token');
      await prefs.remove('username');
      await prefs.remove('expiry_date');
      await _secureStorage.delete(key: 'token');
      log('Session data cleared successfully');
    } catch (e) {
      log('Error clearing session data: $e');
    }
  }

  FutureOr<void> checkSaissionEvent(
    HomeCheckSaissionEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Check token expiry
    final sessionData = await getSessionData();
    if (sessionData['isExpired'] == 'true' || sessionData['token']!.isEmpty) {
      log('Token expired or missing, redirecting to login');
      await deleteSessionData();
      emit(
        state.copyWith(
          status: StateStatus.error,
          error: 'Token expired or missing',
        ),
      );
      return;
    }

    try {
      List<Order> orderList = await OrderService().getOrders();
      emit(
        state.copyWith(
          id: event.id,
          token: event.token,
          username: event.username,
          orderList: orderList,
          status: StateStatus.loaded,
        ),
      );
    } catch (e) {
      log('Failed to fetch orders in checkSaissionEvent: $e');
      if (e.toString().contains('401')) {
        log('Unauthorized: Invalid or expired token');
        await deleteSessionData();
        emit(
          state.copyWith(
            status: StateStatus.error,
            error: 'Token expired or invalid',
          ),
        );
      } else if (e is SocketException ||
          e.toString().contains('SocketException')) {
        emit(
          state.copyWith(
            status: StateStatus.error,
            error: 'Network error: Cannot connect to server',
          ),
        );
      } else if (e is TimeoutException) {
        emit(
          state.copyWith(
            status: StateStatus.error,
            error: 'Network error: Connection timed out',
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: StateStatus.error,
            error: 'Failed to fetch orders: $e',
          ),
        );
      }
    }
  }

  FutureOr<void> toggleThemeEvent(
    HomeToggleThemeEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(isDark: event.isDark));
  }

  FutureOr<void> toggleConnectivityEvent(
    HomeConnectivityEvent event,
    Emitter<HomeState> emit,
  ) {
    if (event.isConnected) {
      emit(state.copyWith(isConnected: true));
    } else {
      emit(state.copyWith(isConnected: false));
    }
  }

  FutureOr<void> addOrderEvent(
    HomeAddOrderEvent event,
    Emitter<HomeState> emit,
  ) async {
    List<Order> newOrderList = List.from(state.orderList);
    Order? newOrder =
        await OrderService().updateOrderStatus(
          event.order.order,
          'up-coming',
          state.username,
          event.order.validationCode,
        ) ??
        Order(
          orderId: "orderId",
          order: "order",
          validationCode: "validationCode",
          customerName: "customerName",
          status: "status",
          reference: "order", // Use order as reference for fallback
          pickupLocation: "pickupLocation",
          customerPhone: "customerPhone",
          deliveryAddress: "deliveryAddress",
          deliveryDate: "deliveryDate",
          deliveryMan: "deliveryMan",
          createdAt: "createdAt",
          updatedAt: "updatedAt",
          orderRef: "orderRef",
          id: "defaultId",
        );
    newOrder = newOrder.copyWith(deliveryMan: state.username);
    newOrderList.add(newOrder);
    emit(state.copyWith(orderList: newOrderList));
  }

  FutureOr<void> changeOrderStatusEvent(
    HomeChangeOrderStatusEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      // First, emit an immediate UI update to show the status change
      int index = state.orderList.indexWhere(
        (element) => element.order == event.order.order,
      );
      if (index != -1) {
        // Create a copy of the order with the new status
        Order updatedOrder = state.orderList[index].copyWith(
          status: event.status,
        );

        // Update the orderList immediately for responsive UI
        List<Order> newOrderList = List.from(state.orderList);
        newOrderList[index] = updatedOrder;
        emit(state.copyWith(orderList: newOrderList));

        // Then update the backend
        log(
          'Updating order status in backend: orderId=${event.order.order}, status=${event.status}',
        );
        Order? serverUpdatedOrder = await OrderService().updateOrderStatus(
          event.order.orderId, // Use orderId instead of order reference
          event.status,
          state.username,
          event.validationCode,
        );

        // If backend update successful, refresh with the server data
        if (serverUpdatedOrder != null) {
          log(
            'Order status updated successfully in backend: ${serverUpdatedOrder.status}',
          );
          // Find the order again as the list might have changed
          int updatedIndex = newOrderList.indexWhere(
            (element) => element.order == event.order.order,
          );
          if (updatedIndex != -1) {
            newOrderList[updatedIndex] = serverUpdatedOrder;
            emit(state.copyWith(orderList: newOrderList));
          }
        } else {
          // If backend update failed, fetch all orders to ensure consistency
          log(
            'Order status update failed or returned null, refreshing all orders',
          );
          List<Order> refreshedOrderList = await OrderService().getOrders();
          emit(state.copyWith(orderList: refreshedOrderList));
        }
      } else {
        log('Order not found in state.orderList: ${event.order.order}');
      }
    } catch (e) {
      log('Error in changeOrderStatusEvent: $e');
      // On error, refresh the full order list to ensure consistent state
      List<Order> refreshedOrderList = await OrderService().getOrders();
      emit(state.copyWith(orderList: refreshedOrderList));
    }
  }

  FutureOr<void> homeNewOrderEvent(
    HomeNewOrderEvent event,
    Emitter<HomeState> emit,
  ) async {
    int index = state.orderList.indexWhere(
      (element) => element.order == event.order.order,
    );
    if (index != -1) {
      Order order = state.orderList[index].copyWith(status: event.order.status);
      List<Order> newOrderList = List.from(state.orderList);
      await OrderService().updateOrderStatus(
        event.order.order,
        event.order.status,
        state.username,
        event.order.validationCode,
      );
      newOrderList[index] = order;
      emit(state.copyWith(orderList: newOrderList));
    }
  }

  FutureOr<void> homeChangeTabScreenEvent(
    HomeChangeTabScreenEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(indexTab: event.index));
  }

  FutureOr<void> uploadImageEvent(
    HomeUploadImageEvent event,
    Emitter<HomeState> emit,
  ) async {
    await UserService.updateUserInformation(
      phone: state.phone,
      address: state.adress,
      fullName: state.fullName,
      email: state.email,
      userId: state.id,
      username: state.username,
      image: event.newProfilePic,
    );

    emit(state.copyWith(profilePic: event.newProfilePic));
  }

  FutureOr<void> changeLanguage(
    HomeChangeLanguage event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(language: event.language));
  }

  FutureOr<void> onFetchDashbordData(
    HomeFetchDashbordData event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(status: StateStatus.loading));
    try {
      emit(
        state.copyWith(
          status: StateStatus.loaded,
          id: event.id,
          token: event.token,
          completedDeliveries: event.dashbordModel.completedDeliveries,
          pendingDeliveries: event.dashbordModel.pendingDeliveries,
          totalCanceled: event.dashbordModel.totalCanceled,
          totalCollected: event.dashbordModel.totalCollected,
          totalDeliveries: event.dashbordModel.totalDeliveries,
          ratings: event.dashbordModel.ratings,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: StateStatus.error));
      log(e.toString());
    }
  }

  FutureOr<void> onChangeIndexPage(
    HomeChangeIndexPage event,
    Emitter<HomeState> emit,
  ) async {
    log('onChangeIndexPage called with index: ${state.navigatorIndex}');
    if (state.navigatorIndex == 1) {
      log('Loading orders for Order tab');
      emit(state.copyWith(status: StateStatus.loading));
      try {
        List<Order> orderList = await OrderService().getOrders();
        log(
          'Orders loaded successfully in onChangeIndexPage: ${orderList.length} orders',
        );
        emit(state.copyWith(orderList: orderList, status: StateStatus.loaded));
      } catch (e) {
        log('Error fetching orders in onChangeIndexPage: $e');
        emit(
          state.copyWith(
            status: StateStatus.error,
            error: 'Failed to fetch orders: $e',
          ),
        );
      }
    }
  }
}
