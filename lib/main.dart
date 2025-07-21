import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

void main() => runApp(const MyApp());

/// Simple logger that prints to console and sends logs to Betterstack.
class BetterstackLogger {
  static const _endpoint = 'https://s1446505.eu-nbg-2.betterstackdata.com/';
  static const _token = 'Bearer UqA2gTDAPEMcyUbqH1RjC98n';

  static Future<void> log(String message) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final body = jsonEncode({'dt': now, 'message': message});
    // Log to console
    // ignore: avoid_print
    print(message);
    try {
      await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': _token,
          'Content-Type': 'application/json',
        },
        body: body,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Failed to send log: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemoZeit',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ReminderPage(),
    );
  }
}

class Reminder {
  final String time;
  final String label;
  final String details;

  const Reminder({required this.time, required this.label, required this.details});

  factory Reminder.fromMap(Map<dynamic, dynamic> map) {
    return Reminder(
      time: map['time']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      details: map['details']?.toString() ?? '',
    );
  }
}

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  static const String dataUrl = 'https://gist.githubusercontent.com/pemo11/34ec46434137767df19657ec3c701fa7/raw/8b0da969e97f0163add0bf3bfcdc197aa74d5e43/memozeit1.yaml';

  List<Reminder> reminders = [];
  String name = '';
  String date = '';
  String? selectedDetails;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    BetterstackLogger.log('App started');
  }

  Future<void> _loadData() async {
    try {
      final response = await http.get(Uri.parse(dataUrl));
      if (response.statusCode == 200) {
        final yamlData = loadYaml(response.body);
        setState(() {
          name = yamlData['name']?.toString() ?? '';
          date = yamlData['date']?.toString() ?? '';
          final list = yamlData['reminders'] as YamlList?;
          reminders = list?.map((e) => Reminder.fromMap(Map<String, dynamic>.from(e))).toList() ?? [];
          loading = false;
        });
        BetterstackLogger.log('Loaded reminders successfully');
      } else {
        BetterstackLogger.log('Failed to fetch data: status ${response.statusCode}');
        setState(() => loading = false);
      }
    } catch (e) {
      BetterstackLogger.log('Error loading data: $e');
      setState(() => loading = false);
    }
  }

  void _selectReminder(Reminder reminder) {
    setState(() => selectedDetails = reminder.details);
    BetterstackLogger.log('Selected reminder: ${reminder.label}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MemoZeit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Erinnerungen für den $date',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Erinnerungen für $name',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: reminders.length,
                      itemBuilder: (context, index) {
                        final r = reminders[index];
                        return ListTile(
                          leading: Text(r.time),
                          title: Text(r.label),
                          onTap: () => _selectReminder(r),
                        );
                      },
                    ),
                  ),
                  if (selectedDetails != null) ...[
                    const Divider(),
                    Text(selectedDetails!),
                  ],
                ],
              ),
      ),
    );
  }
}
