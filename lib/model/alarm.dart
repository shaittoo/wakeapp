import 'package:hive/hive.dart';

part 'alarm.g.dart';

@HiveType(typeId: 0)
class Alarm extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(3)
  double radius;

  @HiveField(4)
  int? distance;

  @HiveField(5)
  int? travelTime;

  @HiveField(6)
  String currentLocation;

  @HiveField(7)
  String destination;

  @HiveField(9)
  double? destinationLat;

  @HiveField(10)
  double? destinationLng;

  @HiveField(8)
  bool startTrip;

  Alarm({
    required this.name,
    required this.radius,
    required this.currentLocation,
    required this.destination,
    this.distance,
    this.travelTime,
    this.startTrip = false,
    this.destinationLat,
    this.destinationLng,
  });
}
