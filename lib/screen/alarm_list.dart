import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/alarm.dart';
import 'dart:math';
import 'edit_alarm_modal.dart';
import 'tracking_screen.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Alarms')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Alarm>('alarms').listenable(),
        builder: (context, Box<Alarm> box, _) {
          if (box.values.isEmpty) {
            return Center(
                child: Text('No alarms set.', style: TextStyle(fontSize: 24)));
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final alarm = box.getAt(index);
              if (alarm == null) return SizedBox.shrink();
              return Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.green.shade200, width: 1),
                ),
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          alarm.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                            fontSize: 18,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue[400]),
                        onPressed: () async {
                          if (alarm == null) return;
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (context) => EditAlarmModal(
                              alarm: alarm,
                              onSave: (updatedAlarm) async {
                                await box.putAt(index, updatedAlarm);
                              },
                            ),
                          );
                        },
                        tooltip: 'Edit Alarm',
                      ),
                      IconButton(
                        icon: Icon(Icons.play_arrow, color: Colors.green[400]),
                        onPressed: () {
                          if (alarm.destinationLat != null && alarm.destinationLng != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TrackingScreen(
                                  destinationName: alarm.name,
                                  destLat: alarm.destinationLat!,
                                  destLng: alarm.destinationLng!,
                                  radius: alarm.radius,
                                  startName: alarm.currentLocation,
                                  destinationAddress: alarm.destination,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Invalid destination coordinates!')),
                            );
                          }
                        },
                        tooltip: 'Start Trip',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red[400]),
                        onPressed: () async {
                          await box.deleteAt(index);
                        },
                        tooltip: 'Delete Alarm',
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 16, color: Colors.green[700]),
                          SizedBox(width: 8),
                          Text(
                            'Set Radius: ${alarm.radius.round()} m',
                            style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.straighten, size: 16, color: Colors.blue[700]),
                          SizedBox(width: 8),
                          Text(
                            'Distance: ' + (() {
                              final latMatch = RegExp(r'Lat: ([\d\.\-]+)').firstMatch(alarm.currentLocation);
                              final lngMatch = RegExp(r'Lng: ([\d\.\-]+)').firstMatch(alarm.currentLocation);
                              double? startLat = latMatch != null ? double.tryParse(latMatch.group(1)!) : null;
                              double? startLng = lngMatch != null ? double.tryParse(lngMatch.group(1)!) : null;
                              final destLatMatch = RegExp(r'Lat: ([\d\.\-]+)').firstMatch(alarm.destination);
                              final destLngMatch = RegExp(r'Lng: ([\d\.\-]+)').firstMatch(alarm.destination);
                              double? destLat = destLatMatch != null ? double.tryParse(destLatMatch.group(1)!) : null;
                              double? destLng = destLngMatch != null ? double.tryParse(destLngMatch.group(1)!) : null;
                              if (startLat != null && startLng != null && destLat != null && destLng != null) {
                                final d = _calculateDistance(startLat, startLng, destLat, destLng).round();
                                return '$d m';
                              }
                              return '-- m';
                            })(),
                            style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.my_location, size: 16, color: Colors.orange[700]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Start Point: ${alarm.currentLocation}',
                              style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w500),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.red[700]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Destination: ${alarm.destination}',
                              style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.w500),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // meters
    final double dLat = (lat2 - lat1) * pi / 180.0;
    final double dLon = (lon2 - lon1) * pi / 180.0;
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) *
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double? extractLat(String destination) {
    final latMatch = RegExp(r'Lat: ([\\d\\.\\-]+)').firstMatch(destination);
    return latMatch != null ? double.tryParse(latMatch.group(1)!) : null;
  }

  double? extractLng(String destination) {
    final lngMatch = RegExp(r'Lng: ([\\d\\.\\-]+)').firstMatch(destination);
    return lngMatch != null ? double.tryParse(lngMatch.group(1)!) : null;
  }
}
