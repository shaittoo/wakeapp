import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/alarm.dart';

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
                  title: Text(
                    alarm.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.circle,
                              size: 16, color: Colors.green[700]),
                          SizedBox(width: 8),
                          Text(
                            'Radius: ${alarm.radius.round()} m',
                            style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.login, size: 16, color: Colors.green[700]),
                          SizedBox(width: 8),
                          Text(
                            'On Enter: ${alarm.onEnter ? "Yes" : "No"}',
                            style: TextStyle(color: Colors.green[800]),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.logout,
                              size: 16, color: Colors.green[700]),
                          SizedBox(width: 8),
                          Text(
                            'On Exit: ${alarm.onExit ? "Yes" : "No"}',
                            style: TextStyle(color: Colors.green[800]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[400]),
                    onPressed: () async {
                      await box.deleteAt(index);
                    },
                    tooltip: 'Delete Alarm',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
