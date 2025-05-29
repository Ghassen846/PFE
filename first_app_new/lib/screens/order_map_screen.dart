import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/google_map_route_utils.dart';
import 'dart:math';

class OrderMapScreen extends StatefulWidget {
  // Order info
  final String orderId;
  final String customerName;
  final String deliveryMan;
  final bool onTheWay;

  // Positions
  final LatLng initialPosition;
  final LatLng restaurantPosition;
  final LatLng customerPosition;

  // Addresses
  final String customerAddress;
  final String restaurantName;
  final String? restaurantAddress;

  const OrderMapScreen({
    Key? key,
    required this.orderId,
    required this.customerName,
    required this.deliveryMan,
    required this.onTheWay,
    required this.initialPosition,
    required this.restaurantPosition,
    required this.customerPosition,
    required this.customerAddress,
    required this.restaurantName,
    this.restaurantAddress,
  }) : super(key: key);

  @override
  State<OrderMapScreen> createState() => _OrderMapScreenState();
}

class _OrderMapScreenState extends State<OrderMapScreen> {
  GoogleMapController? _mapController;
  Set<Polyline> _routes = {};
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _setupRoutes();
    _setupMarkers();
    setState(() => _isLoading = false);
  }

  Future<void> _setupRoutes() async {
    try {
      final routes = await GoogleMapRouteUtils.generateThreePointRoute(
        _mapController,
        [widget.initialPosition.latitude, widget.initialPosition.longitude],
        [
          widget.restaurantPosition.latitude,
          widget.restaurantPosition.longitude,
        ],
        [widget.customerPosition.latitude, widget.customerPosition.longitude],
      );

      if (mounted) {
        setState(() => _routes = routes);
      }
    } catch (e) {
      debugPrint('Error loading routes: $e');
      if (mounted) {
        setState(() {
          _routes = {
            Polyline(
              polylineId: const PolylineId('route1'),
              points: [widget.initialPosition, widget.restaurantPosition],
              color: Colors.blue,
              width: 4,
            ),
            Polyline(
              polylineId: const PolylineId('route2'),
              points: [widget.restaurantPosition, widget.customerPosition],
              color: Colors.green,
              width: 4,
            ),
          };
        });
      }
    }
  }

  void _setupMarkers() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('delivery'),
          position: widget.initialPosition,
          infoWindow: InfoWindow(title: widget.deliveryMan),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
        Marker(
          markerId: const MarkerId('restaurant'),
          position: widget.restaurantPosition,
          infoWindow: InfoWindow(
            title: widget.restaurantName,
            snippet: widget.restaurantAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
        Marker(
          markerId: const MarkerId('customer'),
          position: widget.customerPosition,
          infoWindow: InfoWindow(
            title: widget.customerName,
            snippet: widget.customerAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Route - ${widget.customerName}')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: widget.initialPosition,
                  zoom: 13.0,
                ),
                markers: _markers,
                polylines: _routes,
                mapType: MapType.normal,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                zoomGesturesEnabled: true,
              ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
