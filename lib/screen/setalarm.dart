import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../model/alarm.dart';
import 'package:location/location.dart'; // <-- Add this import
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

const String kGoogleApiKey = 'AIzaSyCv3FFr20CIXT48UA5LdiO_eEffceacY0Q';

class SetAlarmSheet extends StatefulWidget {
  const SetAlarmSheet({super.key});

  @override
  State<SetAlarmSheet> createState() => _SetAlarmSheetState();
}

class _SetAlarmSheetState extends State<SetAlarmSheet> {
  final TextEditingController _alarmNameController =
      TextEditingController(text: "University Area");
  final TextEditingController _currentLocationController =
      TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final String _destinationSessionToken = const Uuid().v4();
  List<dynamic> _destinationSuggestions = [];
  bool _isDestinationSearching = false;
  bool _onEnter = false;
  bool _onExit = true;
  double _radius = 750;

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
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Set Alarm',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900])),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),
            // --- Add these two textboxes here ---
            TextField(
              controller: _currentLocationController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Current Location',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                labelText: 'Destination',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _isDestinationSearching = true;
                });
                _fetchDestinationSuggestions(value);
              },
            ),
            // Add this part for the dropdown suggestions
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
                      title:
                          Text(_destinationSuggestions[index]["description"]),
                      onTap: () async {
                        // Optionally fetch place details here if you want coordinates
                        setState(() {
                          _destinationController.text =
                              _destinationSuggestions[index]["description"];
                          _isDestinationSearching = false;
                          _destinationSuggestions = [];
                        });
                      },
                    );
                  },
                ),
              ),
            SizedBox(height: 16),
            // Alarm Name
            TextField(
              controller: _alarmNameController,
              decoration: InputDecoration(
                labelText: 'Alarm Name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            // On Enter / On Exit
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkboxes and labels
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _onEnter,
                          activeColor: Colors.green,
                          onChanged: (val) => setState(() => _onEnter = val!),
                        ),
                        Text('On Enter'),
                        SizedBox(width: 16),
                        Checkbox(
                          value: _onExit,
                          activeColor: Colors.green,
                          onChanged: (val) => setState(() => _onExit = val!),
                        ),
                        Text('On Exit'),
                      ],
                    ),
                  ],
                ),
                SizedBox(width: 8),
                // Radius controls
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Slider(
                        value: _radius,
                        min: 100,
                        max: 2000,
                        divisions: 19,
                        activeColor: Colors.orange,
                        onChanged: (val) => setState(() => _radius = val),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${_radius.round()} M',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(width: 8),
                          Text('Radius',
                              style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      backgroundColor: Colors.grey[300],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
                      final alarm = Alarm(
                        name: _alarmNameController.text,
                        onEnter: _onEnter,
                        onExit: _onExit,
                        radius: _radius,
                        // repeat: _repeat,
                        // days: List<bool>.from(_days),
                        // favorite: _favorite,
                      );
                      final box = Hive.box<Alarm>('alarms');
                      await box.add(alarm);
                      // ignore: use_build_context_synchronously
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Start Alarm',
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
