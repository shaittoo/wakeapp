import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:location/location.dart';

const kGoogleApiKey = 'AIzaSyCv3FFr20CIXT48UA5LdiO_eEffceacY0Q';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(10.6423590, 122.2309165),
    zoom: 18.0,
  );
  CameraPosition _currentPosition = _kGooglePlex;

  final searchController = TextEditingController();
  final String sessionToken = const Uuid().v4();
  List<dynamic> listOfLocation = [];
  bool isSearching = false;

  final Set<Marker> _markers = {};
  LatLng? _userLatLng;
  bool _userLocationReady = false;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onChange);
    _getUserLocation();
    debugPrint(kGoogleApiKey);
  }

  Future<void> _getUserLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    final userLocation = await location.getLocation();
    setState(() {
      _currentPosition = CameraPosition(
        target: LatLng(userLocation.latitude!, userLocation.longitude!),
        zoom: 16.0,
      );
      _userLatLng = LatLng(userLocation.latitude!, userLocation.longitude!);
      _markers.add(
        Marker(
          markerId: MarkerId('user_location'),
          position: LatLng(userLocation.latitude!, userLocation.longitude!),
          infoWindow: InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      _userLocationReady = true;
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_onChange);
    searchController.dispose();
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
    String baseUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json";
    String request = '$baseUrl?input=$input&key=$kGoogleApiKey&sessiontoken=$sessionToken';
    var response = await http.get(Uri.parse(request));
    if (response.statusCode == 200) {
      setState(() {
        listOfLocation = json.decode(response.body)['predictions'];
      });
      print('API response: ${response.body}');
    } else {
      setState(() {
        listOfLocation = [];
      });
    }
  }

  Future<void> moveToPlace(String placeId, String description) async {
    String detailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$kGoogleApiKey";
    var detailsResponse = await http.get(Uri.parse(detailsUrl));
    var detailsData = json.decode(detailsResponse.body);
    double lat = detailsData['result']['geometry']['location']['lat'];
    double lng = detailsData['result']['geometry']['location']['lng'];
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
    setState(() {
      _currentPosition = CameraPosition(target: LatLng(lat, lng), zoom: 16.0);
      searchController.text = description;
      listOfLocation = [];
      isSearching = false;
      _markers.removeWhere((m) => m.markerId.value == 'searched_location');
      _markers.add(
        Marker(
          markerId: MarkerId('searched_location'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: description),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
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
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              if (_userLocationReady && _userLatLng != null) {
                controller.animateCamera(CameraUpdate.newLatLng(_userLatLng!));
              }
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
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                          title: Text(listOfLocation[index]["description"], style: TextStyle(color: Colors.green[900])),
                          onTap: () => moveToPlace(listOfLocation[index]["place_id"], listOfLocation[index]["description"]),
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
                    final GoogleMapController controller = await _controller.future;
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
                    final GoogleMapController controller = await _controller.future;
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
                    final GoogleMapController controller = await _controller.future;
                    if (_userLatLng != null) {
                      controller.animateCamera(CameraUpdate.newLatLng(_userLatLng!));
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
