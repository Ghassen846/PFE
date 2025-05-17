part of 'home_bloc.dart';

@immutable
abstract class HomeEvent {}

class HomeInitialEvent extends HomeEvent {}

class HomeProductMapFavoriteEvent extends HomeEvent {
  final int index;

  HomeProductMapFavoriteEvent({required this.index});
}

class HomeChangeColor extends HomeEvent {
  final int id;

  HomeChangeColor({required this.id});
}
class HomeChangeIndexPage extends HomeEvent {
  final int index;

  HomeChangeIndexPage({required this.index});
}




class HomeDeleteProdcutFromCartEvent extends HomeEvent {
  final int productId;

  HomeDeleteProdcutFromCartEvent({required this.productId});
}

class HomeNavigateProfileEvent extends HomeEvent {}

class HomeNavigateEvent extends HomeEvent {
  final int currentIndex;
  HomeNavigateEvent({required this.currentIndex});
}


class HomeSignInEvent extends HomeEvent {
  final String email;
  final String password;
  final String token;
  final String id;
    final String username;


  HomeSignInEvent(this.token, this.id, this.username, {required this.email, required this.password});
}



class HomeGetOrdersEvent extends HomeEvent {
  final String token;
  final String id;
  HomeGetOrdersEvent({required this.token,required this.id,});
}

class HomeToggleOrder extends HomeEvent {
  final int reference;
  HomeToggleOrder({required this.reference});
}

class HomeToggleCategory extends HomeEvent {
  final int categoryId;
  HomeToggleCategory({required this.categoryId});
}

class HomeCheckSaissionEvent extends HomeEvent {
  final String token;
  final String id;
  final String username;
  HomeCheckSaissionEvent({required this.token,required this.id,required this.username});
}

class HomeToggleThemeEvent extends HomeEvent {
  final bool isDark;
  HomeToggleThemeEvent({required this.isDark});
}
class HomeConnectivityEvent extends HomeEvent {
  final bool isConnected;
  HomeConnectivityEvent({required this.isConnected});
}
class HomeAddOrderEvent extends HomeEvent
{
  final Order order;
  HomeAddOrderEvent({required this.order});

}
class HomeFetchDashbordData extends HomeEvent 
{
  final String token;
  final String id;
  final DashbordModel dashbordModel;
  HomeFetchDashbordData({required this.token,required this.id,required this.dashbordModel});

}


class HomeChangeOrderStatusEvent extends HomeEvent
{
  final String status;
  final Order order;
   final String validationCode;
  HomeChangeOrderStatusEvent({required this.order,required this.status, this.validationCode=""});

}


class HomeNewOrderEvent extends HomeEvent
{
  final Order order;
  HomeNewOrderEvent({required this.order});

}

class HomeChangeTabScreenEvent extends HomeEvent
{
  final int index;
  HomeChangeTabScreenEvent({required this.index});

}



// ignore: must_be_immutable
class HomeUploadImageEvent extends HomeEvent {
  String newProfilePic;
  HomeUploadImageEvent({required this.newProfilePic});
}


class HomeChangeLanguage extends HomeEvent {
  final String language;
  HomeChangeLanguage({required this.language});
}
