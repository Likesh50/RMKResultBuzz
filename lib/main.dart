import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:telephony/telephony.dart';
import 'package:excel/excel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, String>> phoneMessages = [];
  String? selectedFilePath;
  int totalBatches = 0;
  int currentBatch = 0;
  bool isSending = false;

  final Telephony telephony = Telephony.instance;

  // Function to pick the file
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        selectedFilePath = result.files.single.path;
        // Read file contents
        readFile(result.files.single.path);
      });
    }
  }

  // Function to read file contents
  Future<void> readFile(String? filePath) async {
    if (filePath == null) return;

    try {
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      List<Map<String, String>> tempPhoneMessages = [];

      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet != null) {
          for (var row in sheet.rows) {
            if (row.isNotEmpty && row[0] != null && row[1] != null) {
              tempPhoneMessages.add({
                'phone': row[0]!.value.toString(),
                'message': row[1]!.value.toString(),
              });
            }
          }
        }
      }

      setState(() {
        phoneMessages = tempPhoneMessages;
        totalBatches =
            (phoneMessages.length / 5).ceil(); // Calculate total batches
        currentBatch = 0;
      });
    } catch (e) {
      print("Error reading file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to read file.')),
      );
    }
  }

  // Function to send SMS in batches
  Future<void> sendMessagesInBatches() async {
    const batchSize = 5;
    const delay = Duration(seconds: 30);

    setState(() {
      isSending = true;
    });

    for (int i = 0; i < phoneMessages.length; i += batchSize) {
      final batch = phoneMessages.sublist(
        i,
        i + batchSize > phoneMessages.length
            ? phoneMessages.length
            : i + batchSize,
      );

      for (var item in batch) {
        final phone = item['phone'];
        final message = item['message'];

        if (phone != null && message != null) {
          print('Sending SMS to $phone with message: $message');

          try {
            await telephony.sendSms(
              to: phone,
              message: message,
            );
            print('SMS sent to $phone');
          } catch (e) {
            print("Error sending SMS to $phone: $e");
          }
        }
      }

      setState(() {
        currentBatch++;
      });

      // Notify user about the batch sent
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Batch $currentBatch of $totalBatches sent.')),
      );

      if (i + batchSize < phoneMessages.length) {
        await Future.delayed(delay); // Delay between batches
      }
    }

    setState(() {
      isSending = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Messages sent successfully.')),
    );
  }

  // Function to handle sending SMS with confirmation
  Future<void> handleSendSMS() async {
    if (phoneMessages.length > 50) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirmation'),
          content: Text(
              'You are about to send a large number of messages. Do you want to continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await sendMessagesInBatches();
      }
    } else {
      await sendMessagesInBatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Picker and SMS Sender'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: Text('Pick File'),
            ),
            SizedBox(height: 20),
            if (selectedFilePath != null)
              Text('Selected File: $selectedFilePath'),
            SizedBox(height: 20),
            if (phoneMessages.isNotEmpty)
              Text(
                'Total Batches: $totalBatches\n'
                'Current Batch: $currentBatch',
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSending
                  ? null // Disable button while sending
                  : () {
                      if (phoneMessages.isNotEmpty) {
                        handleSendSMS();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please pick a file.')),
                        );
                      }
                    },
              child: Text('Send Messages'),
            ),
          ],
        ),
      ),
    );
  }
}
