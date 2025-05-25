import 'package:flutter/material.dart';
import 'package:wakeapp/screen/splash_screen.dart';
import 'screen/map_screen.dart';
import 'screen/timer_screen.dart';
import 'package:wakeapp/screen/setalarm.dart' as setalarm;
import 'package:hive_flutter/hive_flutter.dart';
import 'model/alarm.dart';
import 'package:alarm/alarm.dart' as alarm_pkg;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive
    await Hive.initFlutter();
    Hive.registerAdapter(AlarmAdapter());
    await Hive.openBox<Alarm>('alarms');
    
    // Initialize and clean up alarms
    await alarm_pkg.Alarm.init();
    await alarm_pkg.Alarm.stopAll(); // Force stop any running alarms
    
    runApp(const MyApp());
  } catch (e) {
    // log('Error during initialization: $e'); // import 'dart:developer' if you want to use this
    // Still try to run the app even if there's an error
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      home: const SplashScreen(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // Update the static pages list to use the global key
  static List<Widget> _pages = <Widget>[
    MapScreen(key: MapScreen.globalKey),
    TimerScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) => setalarm.SetAlarmSheet(),
          );

          if (result != null && _selectedIndex == 0) {
            MapScreen.globalKey.currentState?.updateDestinationMarker(
              result['name'],
              result['lat'],
              result['lng'],
            );
          }
        },
        backgroundColor: Colors.green,
        shape: CircleBorder(),
        child: Icon(Icons.add, size: 48, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home
              Expanded(
                child: InkWell(
                  onTap: () {
                    _onItemTapped(0); // Navigate to Home (MapScreen)
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home, color: Colors.black),
                      Text('Home', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ),
              // Spacer for FAB
              SizedBox(width: 60),
              // Alarms
              Expanded(
                child: InkWell(
                  onTap: () {
                    _onItemTapped(1); // Navigate to Alarms (TimerScreen)
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alarm, color: Colors.black),
                      Text('Alarms', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> deleteAlarmsBox() async {
  await Hive.deleteBoxFromDisk('alarms');
}
