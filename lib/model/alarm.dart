import 'package:hive/hive.dart';

part 'alarm.g.dart';

@HiveType(typeId: 0)
class Alarm extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  bool onEnter;

  @HiveField(2)
  bool onExit;

  @HiveField(3)
  double radius;

  // @HiveField(4)
  // bool repeat;

  // @HiveField(5)
  // List<bool> days;

  // @HiveField(6)
  // bool favorite;

  Alarm({
    required this.name,
    required this.onEnter,
    required this.onExit,
    required this.radius,
    // required this.repeat,
    // required this.days,
    // required this.favorite,
  });
}
