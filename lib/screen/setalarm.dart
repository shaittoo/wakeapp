import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../model/alarm.dart';
import 'package:location/location.dart'; // <-- Add this import
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'Components/semi_circle_slider.dart';
import 'tracking_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

const String kGoogleApiKey = '';

class SetAlarmSheet extends StatefulWidget {
  const SetAlarmSheet({super.key});

  @override
  State<SetAlarmSheet> createState() => _SetAlarmSheetState();
}

class _SetAlarmSheetState extends State<SetAlarmSheet> {
  final TextEditingController _alarmNameController =
      TextEditingController(text: "My Alarm");
  final TextEditingController _currentLocationController =
      TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final String _destinationSessionToken = const Uuid().v4();
  List<dynamic> _destinationSuggestions = [];
  bool _isDestinationSearching = false;
  double _radius = 750;

  // Add these variables to store selected location
  String? _selectedDescription;
  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();
    _fetchAndSetCurrentLocation();
  }

  Future<void> _fetchAndSetCurrentLocation() async {
    Location location = Location();
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
    if (userLocation.latitude != null && userLocation.longitude != null) {
      setState(() {
        _currentLocationController.text =
            'Lat: ${userLocation.latitude!.toStringAsFixed(5)}, Lng: ${userLocation.longitude!.toStringAsFixed(5)}';
      });
    } else {
      setState(() {
        _currentLocationController.text = 'Unknown';
      });
    }
  }

  Future<void> _fetchDestinationSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _destinationSuggestions = [];
      });
      return;
    }
    String baseUrl =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json";
    String request =
        '$baseUrl?input=$input&key=$kGoogleApiKey&sessiontoken=$_destinationSessionToken';
    var response = await http.get(Uri.parse(request));
    if (response.statusCode == 200) {
      setState(() {
        _destinationSuggestions = json.decode(response.body)['predictions'];
      });
    } else {
      setState(() {
        _destinationSuggestions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Create Trip Alarm',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800])),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Let us wake you up, so you don't miss your destination.",
                style: TextStyle(fontSize: 13, color: Colors.grey[800]),
              ),
            ),
            SizedBox(height: 12),
            // Start and End locations
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(Icons.radio_button_checked, color: Colors.green, size: 20),
                    Container(width: 2, height: 32, color: Colors.green[200]),
                    Icon(Icons.location_on, color: Colors.blue, size: 20),
                  ],
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: _currentLocationController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Start location',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.green, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.green, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.green, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _destinationController,
                        decoration: InputDecoration(
                          hintText: 'Destination',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.green, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.green, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.green, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _isDestinationSearching = true;
                          });
                          _fetchDestinationSuggestions(value);
                        },
                      ),
                      if (_isDestinationSearching && _destinationSuggestions.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          constraints: BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _destinationSuggestions.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(_destinationSuggestions[index]["description"]),
                                onTap: () async {
                                  String placeId = _destinationSuggestions[index]["place_id"];
                                  String description = _destinationSuggestions[index]["description"];
                                  String detailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$kGoogleApiKey";
                                  var detailsResponse = await http.get(Uri.parse(detailsUrl));
                                  var detailsData = json.decode(detailsResponse.body);
                                  double lat = detailsData['result']['geometry']['location']['lat'];
                                  double lng = detailsData['result']['geometry']['location']['lng'];
                                  setState(() {
                                    _destinationController.text = description;
                                    _isDestinationSearching = false;
                                    _destinationSuggestions = [];
                                    _selectedDescription = description;
                                    _selectedLat = lat;
                                    _selectedLng = lng;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Set alarm name label
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 4.0, bottom: 4),
                child: Text(
                  'Set Alarm Name',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green[900]),
                ),
              ),
            ),
            // Set alarm name input box
            TextField(
              controller: _alarmNameController,
              decoration: InputDecoration(
                hintText: 'Enter Alarm Name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
            ),
            SizedBox(height: 16),

            // Semi-circle radius controller
            Center(
              child: SemiCircleSlider(
                min: 100,
                max: 1000,
                value: _radius,
                onChanged: (val) => setState(() => _radius = val),
                unit: 'M',
              ),
            ),
            SizedBox(height: 30),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.green),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      List<String> missingFields = [];
                      if (_alarmNameController.text.trim().isEmpty) {
                        missingFields.add('Alarm Name');
                      }
                      if (_destinationController.text.trim().isEmpty || _selectedLat == null || _selectedLng == null) {
                        missingFields.add('Destination');
                      }
                      if (missingFields.isNotEmpty) {
                        Fluttertoast.showToast(
                          msg: 'Please fill in: ' + missingFields.join(', '),
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.TOP,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                        return;
                      } 
                      final alarm = Alarm(
                        name: _alarmNameController.text,
                        radius: _radius,
                        currentLocation: _currentLocationController.text,
                        destination: _destinationController.text,
                        destinationLat: _selectedLat,
                        destinationLng: _selectedLng,
                      );
                      final box = Hive.box<Alarm>('alarms');
                      await box.add(alarm);
                      if (mounted) {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrackingScreen(
                              destinationName: _alarmNameController.text,
                              destLat: _selectedLat!,
                              destLng: _selectedLng!,
                              radius: _radius,
                              startName: _currentLocationController.text,
                              destinationAddress: _destinationController.text,
                            ),
                          ),
                        );
                      }
                    },
                    child: Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
