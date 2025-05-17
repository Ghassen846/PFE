part of 'home_bloc.dart';

enum StateStatus {
  initial,
  loading,
  loaded,
  failed,
  error,
  checkOut,
  checkOutFailed,
  orderState,
}

class HomeState {
  final String username;
  final double total;
  final StateStatus status;
  final int navigatorIndex;
  final String id;
  final String token;
  final bool isDark;
  final bool isConnected;
  final List<Order> orderList;
  final int indexTab;
  final String profilePic;
  final String fullName;
  final String adress;
  final String phone;
  final String email;
  final String language;
  final int ratings;
  final int totalDeliveries;
  final int totalCanceled;
  final int pendingDeliveries;
  final String totalCollected;
  final int completedDeliveries;
  final String? error;

  const HomeState({
    this.profilePic = "",
    this.indexTab = 0,
    this.orderList = const [],
    this.isConnected = true,
    this.isDark = true,
    this.status = StateStatus.initial,
    this.navigatorIndex = 0,
    this.id = "",
    this.token = "",
    this.username = "",
    this.total = 0.0,
    this.fullName = "",
    this.adress = "",
    this.phone = "",
    this.email = "",
    this.language = "en",
    this.ratings = 0,
    this.totalDeliveries = 0,
    this.totalCanceled = 0,
    this.pendingDeliveries = 0,
    this.totalCollected = "0",
    this.completedDeliveries = 0,
    this.error,
  });

  List<Object?> get props => [
    username,
    total,
    status,
    navigatorIndex,
    id,
    token,
    isDark,
    isConnected,
    orderList,
    indexTab,
    profilePic,
    fullName,
    adress,
    phone,
    email,
    language,
    ratings,
    totalDeliveries,
    totalCanceled,
    pendingDeliveries,
    totalCollected,
    completedDeliveries,
    error,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HomeState &&
        other.username == username &&
        other.total == total &&
        other.status == status &&
        other.navigatorIndex == navigatorIndex &&
        other.id == id &&
        other.token == token &&
        other.isDark == isDark &&
        other.isConnected == isConnected &&
        other.indexTab == indexTab &&
        other.profilePic == profilePic &&
        other.fullName == fullName &&
        other.adress == adress &&
        other.phone == phone &&
        other.email == email &&
        other.language == language &&
        other.ratings == ratings &&
        other.totalDeliveries == totalDeliveries &&
        other.totalCanceled == totalCanceled &&
        other.pendingDeliveries == pendingDeliveries &&
        other.totalCollected == totalCollected &&
        other.completedDeliveries == completedDeliveries &&
        other.error == error;
  }

  @override
  int get hashCode {
    final List<Object?> values = [
      username,
      total,
      status,
      navigatorIndex,
      id,
      token,
      isDark,
      isConnected,
      indexTab,
      profilePic,
      fullName,
      adress,
      phone,
      email,
      language,
      ratings,
      totalDeliveries,
      totalCanceled,
      pendingDeliveries,
      totalCollected,
      completedDeliveries,
      error,
    ];
    return Object.hashAll(values);
  }

  HomeState copyWith({
    String? username,
    double? total,
    StateStatus? status,
    int? navigatorIndex,
    String? id,
    String? token,
    bool? isDark,
    bool? isConnected,
    List<Order>? orderList,
    int? indexTab,
    String? profilePic,
    String? fullName,
    String? adress,
    String? phone,
    String? email,
    String? language,
    int? ratings,
    int? totalDeliveries,
    int? totalCanceled,
    int? pendingDeliveries,
    String? totalCollected,
    int? completedDeliveries,
    String? error,
  }) {
    return HomeState(
      username: username ?? this.username,
      total: total ?? this.total,
      status: status ?? this.status,
      navigatorIndex: navigatorIndex ?? this.navigatorIndex,
      id: id ?? this.id,
      token: token ?? this.token,
      isDark: isDark ?? this.isDark,
      isConnected: isConnected ?? this.isConnected,
      orderList: orderList ?? this.orderList,
      indexTab: indexTab ?? this.indexTab,
      profilePic: profilePic ?? this.profilePic,
      fullName: fullName ?? this.fullName,
      adress: adress ?? this.adress,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      language: language ?? this.language,
      ratings: ratings ?? this.ratings,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      totalCanceled: totalCanceled ?? this.totalCanceled,
      pendingDeliveries: pendingDeliveries ?? this.pendingDeliveries,
      totalCollected: totalCollected ?? this.totalCollected,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      error: error ?? this.error,
    );
  }

  factory HomeState.fromDashboardModel(
    DashbordModel model,
    HomeState currentState,
  ) {
    // Since deliveryMan is a String in the model, we'll just use existing values
    return currentState.copyWith(
      id: model.id,
      // We keep existing values for fields that don't map directly to the model
      completedDeliveries: model.completedDeliveries,
      pendingDeliveries: model.pendingDeliveries,
      totalDeliveries: model.totalDeliveries,
      totalCanceled: model.totalCanceled,
      totalCollected: model.totalCollected,
      ratings: model.ratings,
    );
  }
}
