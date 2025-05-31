import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../model/alarm.dart';
import 'Components/semi_circle_slider.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String kGoogleApiKey = 'AIzaSyCv3FFr20CIXT48UA5LdiO_eEffceacY0Q';

class EditAlarmModal extends StatefulWidget {
  final Alarm alarm;
  final void Function(Alarm updatedAlarm) onSave;
  const EditAlarmModal({Key? key, required this.alarm, required this.onSave}) : super(key: key);

  @override
  State<EditAlarmModal> createState() => _EditAlarmModalState();
}

class _EditAlarmModalState extends State<EditAlarmModal> {
  late TextEditingController _alarmNameController;
  late TextEditingController _currentLocationController;
  late TextEditingController _destinationController;
  double _radius = 750;
  double? _selectedLat;
  double? _selectedLng;

  final String _destinationSessionToken = const Uuid().v4();
  List<dynamic> _destinationSuggestions = [];
  bool _isDestinationSearching = false;

  @override
  void initState() {
    super.initState();
    _alarmNameController = TextEditingController(text: widget.alarm.name);
    _currentLocationController = TextEditingController(text: widget.alarm.currentLocation);
    _destinationController = TextEditingController(text: widget.alarm.destination);
    _radius = widget.alarm.radius;
    _selectedLat = widget.alarm.destinationLat;
    _selectedLng = widget.alarm.destinationLng;
  }

  @override
  void dispose() {
    _alarmNameController.dispose();
    _currentLocationController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _save() {
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
    final updatedAlarm = Alarm(
      name: _alarmNameController.text,
      radius: _radius,
      currentLocation: _currentLocationController.text,
      destination: _destinationController.text,
      distance: widget.alarm.distance,
      travelTime: widget.alarm.travelTime,
      startTrip: widget.alarm.startTrip,
      destinationLat: _selectedLat,
      destinationLng: _selectedLng,
    );
    widget.onSave(updatedAlarm);
    Navigator.pop(context);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Edit Alarm',
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
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Edit your alarm details.",
                style: TextStyle(fontSize: 13, color: Colors.grey[800]),
              ),
            ),
            SizedBox(height: 12),
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
                          _selectedLat = lat;
                          _selectedLng = lng;
                        });
                      },
                    );
                  },
                ),
              ),
            SizedBox(height: 12),
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
                    onPressed: _save,
                    child: Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
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
