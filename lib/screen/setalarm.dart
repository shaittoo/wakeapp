import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../model/alarm.dart';
import 'package:location/location.dart'; // <-- Add this import
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
// import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:alarm/alarm.dart' as alarm_pkg;
import 'package:alarm/model/alarm_settings.dart';
import 'package:alarm/model/notification_settings.dart';
import 'package:vibration/vibration.dart';

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
  double _radius = 750;
  bool _alarmSoundEnabled = true;
  bool _vibrationEnabled = false;
  bool _notifyEarlierEnabled = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _fetchAndSetCurrentLocation();
    _initNotifications();
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

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> setAlarm(DateTime dateTime) async {
    try {
      // First stop any existing alarms
      await alarm_pkg.Alarm.stopAll();
      
      final alarmSettings = AlarmSettings(
        id: DateTime.now().millisecondsSinceEpoch % 100000, // unique id
        dateTime: dateTime,
        assetAudioPath: 'assets/AlarmClock.mp3',
        loopAudio: _alarmSoundEnabled,
        vibrate: _vibrationEnabled,
        notificationSettings: NotificationSettings(
          title: 'Alarm',
          body: 'Your alarm is ringing!',
        ),
        volume: 0.8,
        fadeDuration: 2.0,
      );
      
      await alarm_pkg.Alarm.set(alarmSettings: alarmSettings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alarm set for ${dateTime.toLocal()}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting alarm: $e')),
        );
      }
    }
  }

  Future<void> stopAlarm() async {
    try {
      // Force stop all alarms and audio
      await alarm_pkg.Alarm.stopAll();
      
      // Additional cleanup
      final alarms = await alarm_pkg.Alarm.getAlarms();
      for (var alarm in alarms) {
        await alarm_pkg.Alarm.stop(alarm.id);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alarm stopped')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping alarm: $e')),
        );
      }
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
                        color: Colors.green[700])),
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
            // Radius controls
            Slider(
              value: _radius,
              min: 100,
              max: 2000,
              divisions: 19,
              activeColor: Colors.green,
              onChanged: (val) => setState(() => _radius = val),
            ),
            Text(
              '	${_radius.round()} M',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            // --- New Alarm Settings Section ---
            SizedBox(height: 18),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alarm Settings',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Divider(),
                  _buildSettingsRow(
                    title: 'Alarm sound',
                    subtitle: 'Wizkid ft Tems | Essence',
                    value: _alarmSoundEnabled,
                    onChanged: (val) => setState(() => _alarmSoundEnabled = val),
                    activeColor: Colors.green,
                  ),
                  Divider(),
                  _buildSettingsRow(
                    title: 'Vibration',
                    subtitle: _vibrationEnabled ? '' : 'None',
                    value: _vibrationEnabled,
                    onChanged: (val) => setState(() => _vibrationEnabled = val),
                    activeColor: Colors.green,
                  ),
                  Divider(),
                  _buildSettingsRow(
                    title: 'Notify me on radius',
                    subtitle: _notifyEarlierEnabled ? '' : 'None',
                    value: _notifyEarlierEnabled,
                    onChanged: (val) => setState(() => _notifyEarlierEnabled = val),
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Temporary test button for alarm trigger
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Set alarm for 1 minute from now for demo
                      final now = DateTime.now();
                      await setAlarm(now.add(Duration(minutes: 1)));
                      if (_vibrationEnabled && await Vibration.hasVibrator()) {
                        Vibration.vibrate(duration: 1000); // vibrate for 1 second
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Set Alarm for 1 Minute from Now'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: stopAlarm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Stop Alarm'),
                  ),
                ),
              ],
            ),
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
                        onEnter: false,
                        onExit: false,
                        radius: _radius,
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

  Widget _buildSettingsRow({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged, required Color activeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }
}
