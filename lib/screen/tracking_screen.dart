import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'dart:math';

class TrackingScreen extends StatefulWidget {
  final String destinationName;
  final double destLat;
  final double destLng;
  final double radius;
  final String? startName;
  final String? destinationAddress;

  const TrackingScreen({
    Key? key,
    required this.destinationName,
    required this.destLat,
    required this.destLng,
    required this.radius,
    this.startName,
    this.destinationAddress,
  }) : super(key: key);

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late GoogleMapController _mapController;
  Location location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  LatLng? _userLatLng;
  bool _alarmed = false;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  Future<void> _initLocationTracking() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }
    final userLocation = await location.getLocation();
    _updateUserLocation(userLocation);
    _locationSubscription = location.onLocationChanged.listen((newLocation) {
      _updateUserLocation(newLocation);
    });
  }

  void _updateUserLocation(LocationData userLocation) {
    if (userLocation.latitude == null || userLocation.longitude == null) return;
    final LatLng userLatLng = LatLng(userLocation.latitude!, userLocation.longitude!);
    setState(() {
      _userLatLng = userLatLng;
    });
    _checkAlarm(userLatLng);
  }

  void _checkAlarm(LatLng userLatLng) {
    final double distance = _calculateDistance(
      userLatLng.latitude,
      userLatLng.longitude,
      widget.destLat,
      widget.destLng,
    );
    if (!_alarmed && distance <= widget.radius) {
      _alarmed = true;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Alarm!'),
          content: Text('You have entered your destination radius.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // Earth radius in meters
    final double dLat = (lat2 - lat1) * 3.141592653589793 / 180.0;
    final double dLon = (lon2 - lon1) * 3.141592653589793 / 180.0;
    final double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1 * 3.141592653589793 / 180.0) *
            cos(lat2 * 3.141592653589793 / 180.0) *
            (sin(dLon / 2) * sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng destination = LatLng(widget.destLat, widget.destLng);
    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking Your Location'),
        centerTitle: true,
        leading: BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: destination,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: {
              Marker(
                markerId: MarkerId('destination'),
                position: destination,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              ),
              if (_userLatLng != null)
                Marker(
                  markerId: MarkerId('user'),
                  position: _userLatLng!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
            },
            polylines: {
              if (_userLatLng != null)
                Polyline(
                  polylineId: PolylineId('route'),
                  color: Colors.orange,
                  width: 6,
                  points: [_userLatLng!, destination],
                ),
            },
            onMapCreated: (controller) => _mapController = controller,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.destinationName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Distance', style: TextStyle(color: Colors.grey[700])),
                          Text('${(widget.radius / 1000).toStringAsFixed(1)} KM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Set Radius', style: TextStyle(color: Colors.grey[700])),
                          Text('${widget.radius.round()} m', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.red, size: 20),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.startName ?? 'Current Location',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue, size: 20),
                          SizedBox(width: 6),
                          Expanded(
                            child: (widget.destinationAddress != null && widget.destinationAddress!.isNotEmpty)
                                ? Text(
                                    widget.destinationAddress!,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  )
                                : SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF7B61FF),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // TODO: Implement start trip logic
                      },
                      child: Text(
                        'Start My Trip',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 