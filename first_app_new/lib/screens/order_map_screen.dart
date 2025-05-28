import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../helpers/shared.dart' as shared;

class OrderMapScreen extends StatefulWidget {
  final shared.LatLng initialPosition;
  final String orderId;
  final String customerName;
  final String deliveryMan;
  final bool onTheWay;
  final String adress;

  const OrderMapScreen({
    super.key,
    required this.initialPosition,
    required this.orderId,
    required this.customerName,
    required this.deliveryMan,
    required this.onTheWay,
    required this.adress,
  });

  @override
  State<OrderMapScreen> createState() => _OrderMapScreenState();
}

class _OrderMapScreenState extends State<OrderMapScreen> {
  late LatLng _center;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _center = LatLng(
      widget.initialPosition.latitude,
      widget.initialPosition.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.onTheWay ? 'Delivery Location' : 'Pickup Location'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: _center, initialZoom: 15.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _center,
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          Icon(Icons.location_on, color: Colors.red, size: 40),
                          Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 2),
                              ],
                            ),
                            child: Text(
                              widget.onTheWay ? 'Delivery' : 'Pickup',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ID: ${widget.orderId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Customer: ${widget.customerName}'),
                const SizedBox(height: 8),
                Text('Delivery Person: ${widget.deliveryMan}'),
                const SizedBox(height: 8),
                Text('Address: ${widget.adress}'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Return to previous screen
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text(
                      'Back to Orders',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
