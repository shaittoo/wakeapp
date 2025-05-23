import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../model/alarm.dart';

class SetAlarmSheet extends StatefulWidget {
  const SetAlarmSheet({super.key});

  @override
  State<SetAlarmSheet> createState() => _SetAlarmSheetState();
}

class _SetAlarmSheetState extends State<SetAlarmSheet> {
  final TextEditingController _alarmNameController =
      TextEditingController(text: "University Area");
  bool _onEnter = false;
  bool _onExit = true;
  double _radius = 750;
  // bool _repeat = false;
  // // ignore: prefer_final_fields
  // List<bool> _days = [false, false, true, false, false, false, false]; // WED selected
  // bool _favorite = true;

  // final List<String> _dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkboxes and labels
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Checkboxes Row
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
                      // Radius controls
                      Slider(
                        value: _radius,
                        min: 100,
                        max: 2000,
                        divisions: 19,
                        activeColor: Colors.orange,
                        onChanged: (val) => setState(() => _radius = val),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center, // Center horizontally
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_radius.round()} M',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Radius',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(width: 8),
                ],
              ),
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
                      Navigator.pop(context);
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
