import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:location/location.dart';

const kGoogleApiKey = 'AIzaSyCv3FFr20CIXT48UA5LdiO_eEffceacY0Q';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  static final GlobalKey<_MapScreenState> globalKey =
      GlobalKey<_MapScreenState>();

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(10.6426908, 122.2311146),
    zoom: 16.0,
  );
  CameraPosition _currentPosition = _kGooglePlex;
  double _currentZoom = 18.0;

  final searchController = TextEditingController();
  final String sessionToken = const Uuid().v4();
  List<dynamic> listOfLocation = [];
  bool isSearching = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _userLatLng;
  bool _userLocationReady = false;

  Location location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onChange);
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

    // Get initial location
    final userLocation = await location.getLocation();
    _updateUserLocation(userLocation);

    // Listen for location changes
    _locationSubscription = location.onLocationChanged.listen((newLocation) {
      _updateUserLocation(newLocation, animate: false);
    });
  }

  void _updateUserLocation(LocationData userLocation,
      {bool animate = false}) async {
    if (userLocation.latitude == null || userLocation.longitude == null) return;
    final LatLng userLatLng =
        LatLng(userLocation.latitude!, userLocation.longitude!);

    setState(() {
      _userLatLng = userLatLng;
      _markers.removeWhere((m) => m.markerId.value == 'user_location');
      _markers.add(
        Marker(
          markerId: MarkerId('user_location'),
          position: userLatLng,
          infoWindow: InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      _userLocationReady = true;
    });

    if (animate && _controller.isCompleted) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: userLatLng,
            zoom: _currentZoom,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    searchController.removeListener(_onChange);
    searchController.dispose();
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _onChange() {
    if (searchController.text.isNotEmpty) {
      setState(() {
        isSearching = true;
      });
      placeSuggestion(searchController.text);
    } else {
      setState(() {
        isSearching = false;
        listOfLocation = [];
      });
    }
  }

  void placeSuggestion(String input) async {
    String baseUrl =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json";
    String request =
        '$baseUrl?input=$input&key=$kGoogleApiKey&sessiontoken=$sessionToken';
    var response = await http.get(Uri.parse(request));
    if (response.statusCode == 200) {
      setState(() {
        listOfLocation = json.decode(response.body)['predictions'];
      });
    } else {
      setState(() {
        listOfLocation = [];
      });
    }
  }

  Future<void> moveToPlace(String placeId, String description) async {
    String detailsUrl =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$kGoogleApiKey";
    var detailsResponse = await http.get(Uri.parse(detailsUrl));
    var detailsData = json.decode(detailsResponse.body);
    double lat = detailsData['result']['geometry']['location']['lat'];
    double lng = detailsData['result']['geometry']['location']['lng'];
    final LatLng destination = LatLng(lat, lng);
    
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(destination));
    
    setState(() {
      _currentPosition = CameraPosition(target: destination, zoom: _currentZoom);
      searchController.text = description;
      listOfLocation = [];
      isSearching = false;
      _markers.removeWhere((m) => m.markerId.value == 'searched_location');
      _markers.add(
        Marker(
          markerId: MarkerId('searched_location'),
          position: destination,
          infoWindow: InfoWindow(title: description),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });

    // Get route points if user location is available
    if (_userLatLng != null) {
      final routePoints = await _getRouteCoordinates(_userLatLng!, destination);
      print('Route points: ' + routePoints.length.toString());
      if (routePoints.isNotEmpty) {
        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: PolylineId('route'),
              color: Colors.blue,
              width: 5,
              points: routePoints,
            ),
          );
        });
      } else {
        setState(() {
          _polylines.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No route found between your location and the destination.')),
          );
        }
      }
      // Always adjust the camera to show both pins
      _showBothMarkers();
    } else {
      print('User location not available for route drawing.');
    }
  }

  // Add this method to fetch route points
  Future<List<LatLng>> _getRouteCoordinates(
      LatLng origin, LatLng destination) async {
    print(
        'Fetching route from ${origin.latitude},${origin.longitude} to ${destination.latitude},${destination.longitude}');

    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$kGoogleApiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      // Add this debug print to see the full response
      print('Full Response: ${response.body}');
      print('Directions API response status: ${decoded['status']}');

      if (decoded['status'] == 'OK') {
        final route = decoded['routes'][0]['overview_polyline']['points'];
        final routePoints = _decodePolyline(route);
        print('Route points fetched: ${routePoints.length}');
        return routePoints;
      } else {
        // Add this to see why the status isn't 'OK'
        print(
            'API Error: ${decoded['status']} - ${decoded['error_message'] ?? 'No error message'}');
      }
    }

    print('Failed to fetch route: ${response.statusCode}');
    return [];
  }

  // Add this helper method to decode Google's polyline string
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }
    return points;
  }

  // Modify the updateDestinationMarker method
  void updateDestinationMarker(String name, double lat, double lng) async {
    print('MapScreen: Updating destination marker');
    print('Location: $name');
    print('Coordinates: ($lat, $lng)');

    final destination = LatLng(lat, lng);

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'destination');
      _markers.add(
        Marker(
          markerId: MarkerId('destination'),
          position: destination,
          infoWindow: InfoWindow(title: name),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    });

    // Get the route points
    if (_userLatLng != null) {
      final routePoints = await _getRouteCoordinates(_userLatLng!, destination);

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: routePoints,
          ),
        );
      });
    }

    _showBothMarkers();
  }

  // Add this helper method to show both markers
  void _showBothMarkers() async {
    if (_userLatLng != null && _markers.length >= 2) {
      final GoogleMapController controller = await _controller.future;

      // Find the destination marker
      final destinationMarker = _markers.firstWhere(
        (m) => m.markerId.value == 'destination',
        orElse: () => _markers.first,
      );

      // Calculate bounds that include both markers with padding
      final bounds = LatLngBounds(
        southwest: LatLng(
          min(_userLatLng!.latitude, destinationMarker.position.latitude),
          min(_userLatLng!.longitude, destinationMarker.position.longitude),
        ),
        northeast: LatLng(
          max(_userLatLng!.latitude, destinationMarker.position.latitude),
          max(_userLatLng!.longitude, destinationMarker.position.longitude),
        ),
      );

      // Calculate padding based on screen size
      final padding = MediaQuery.of(context).size.height * 0.25;

      try {
        // Animate camera to show both markers
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, padding),
        );
      } catch (e) {
        print('Error adjusting camera view: $e');
        // Fallback to a default zoom if bounds calculation fails
        final centerLat =
            (_userLatLng!.latitude + destinationMarker.position.latitude) / 2;
        final centerLng =
            (_userLatLng!.longitude + destinationMarker.position.longitude) / 2;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(centerLat, centerLng),
              zoom: 15,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _currentPosition,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onCameraMove: (CameraPosition position) {
              _currentZoom = position.zoom;
            },
            zoomGesturesEnabled: true,
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Location...',
                      prefixIcon: Icon(Icons.search, color: Colors.green),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: TextStyle(color: Colors.green[900]),
                  ),
                ),
                if (isSearching && listOfLocation.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB(188, 12, 90, 12),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: listOfLocation.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(listOfLocation[index]["description"],
                              style: TextStyle(color: Colors.green[900])),
                          onTap: () => moveToPlace(
                              listOfLocation[index]["place_id"],
                              listOfLocation[index]["description"]),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 110,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'layer',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {},
              child: Icon(Icons.layers, color: Colors.green),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () async {
                    final GoogleMapController controller =
                        await _controller.future;
                    controller.animateCamera(CameraUpdate.zoomIn());
                  },
                  child: Icon(Icons.add, color: Colors.green),
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () async {
                    final GoogleMapController controller =
                        await _controller.future;
                    controller.animateCamera(CameraUpdate.zoomOut());
                  },
                  child: Icon(Icons.remove, color: Colors.green),
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'center',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () async {
                    final GoogleMapController controller =
                        await _controller.future;
                    if (_userLatLng != null) {
                      controller.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: _userLatLng!,
                            zoom: 19.5, // Street-level zoom
                          ),
                        ),
                      );
                    }
                  },
                  child: Icon(Icons.my_location, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
