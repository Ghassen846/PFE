import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderMapScreen extends StatefulWidget {
  final LatLng initialPosition;
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
  GoogleMapController? _mapController;
  LatLng? _center;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _center = widget.initialPosition;
    _setupMarkers();
  }

  void _setupMarkers() {
    // Add marker for the delivery location
    _markers.add(
      Marker(
        markerId: MarkerId('delivery_${widget.orderId}'),
        position: _center!,
        infoWindow: InfoWindow(
          title: widget.onTheWay ? 'Delivery Location' : 'Pickup Location',
          snippet: widget.adress,
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
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
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center!,
                zoom: 15.0,
              ),
              markers: _markers,
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
