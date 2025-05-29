import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

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
  bool _modalCollapsed = false;
  bool _tripStarted = false;

  @override
  void initState() {
    super.initState();
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
        barrierDismissible: false,
        builder: (context) => AlarmDialog(
          onStop: () {
            setState(() {
              _alarmed = false;
            });
            Navigator.of(context).pop();
          },
          destLat: widget.destLat,
          destLng: widget.destLng,
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

  void _startTrip() {
    if (!_tripStarted) {
      setState(() {
        _tripStarted = true;
        _modalCollapsed = true;
      });
      _initLocationTracking();
    }
  }

  void _cancelTrip() {
    setState(() {
      _tripStarted = false;
      _modalCollapsed = false;
    });
    _locationSubscription?.cancel();
    _userLatLng = null;
    _alarmed = false;
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
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 250),
              child: _modalCollapsed
                  ? GestureDetector(
                      key: ValueKey('collapsed'),
                      onTap: () => setState(() => _modalCollapsed = false),
                      child: Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                        child: Center(
                          child: Text(
                            widget.destinationName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Stack(
                      key: ValueKey('expanded'),
                      children: [
                        Container(
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    widget.destinationName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.expand_more, color: Colors.grey[700]),
                                    onPressed: () => setState(() => _modalCollapsed = true),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
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
                              SizedBox(height: 8),
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
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                          style: TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, color: Colors.blue, size: 20),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: (widget.destinationAddress != null && widget.destinationAddress!.isNotEmpty)
                                            ? Text(
                                                widget.destinationAddress!,
                                                softWrap: true,
                                                overflow: TextOverflow.visible,
                                                style: TextStyle(fontWeight: FontWeight.w500),
                                              )
                                            : SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: _tripStarted
                                    ? ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: _cancelTrip,
                                        child: Text(
                                          'Cancel Trip',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      )
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF7B61FF),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: _startTrip,
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
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class AlarmDialog extends StatefulWidget {
  final VoidCallback onStop;
  final double destLat;
  final double destLng;
  const AlarmDialog({Key? key, required this.onStop, required this.destLat, required this.destLng}) : super(key: key);

  @override
  State<AlarmDialog> createState() => _AlarmDialogState();
}

class _AlarmDialogState extends State<AlarmDialog> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playAlarm();
  }

  Future<void> _playAlarm() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('alarm.mp3'));
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4),
      body: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 32),
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color(0xFFFDECEC),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_active, color: Colors.red, size: 40),
              ),
              SizedBox(height: 8),
              Text('Wake UP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 4),
              Text('You are near your destination !', style: TextStyle(fontSize: 13)),
              SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: Colors.grey[200],
                  width: 250,
                  height: 100,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.destLat, widget.destLng),
                      zoom: 16,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId('dest'),
                        position: LatLng(widget.destLat, widget.destLng),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                      ),
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    scrollGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    liteModeEnabled: true,
                  ),
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: 175,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                    minimumSize: Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    widget.onStop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text('Exit Trip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 