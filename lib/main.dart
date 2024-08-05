import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:telephony/telephony.dart';
import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  // Restrict the app to only portrait mode
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(ResultBuzzApp());
}

class ResultBuzzApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Result Buzz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Poppins',
      ),
      home: ResultBuzzPage(),
    );
  }
}

class AssessmentDropdown extends StatefulWidget {
  @override
  _AssessmentDropdownState createState() => _AssessmentDropdownState();
}

class _AssessmentDropdownState extends State<AssessmentDropdown> {
  String _selectedAssessment = 'Select assessment type';
  final List<String> _assessments = [
    'Select assessment type',
    'Unit Test-1',
    'Unit Test-2',
    'First Internal Assessment',
    'Second Internal Assessment',
    'Model Exam',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: EdgeInsets.all(16),
      width: double.infinity,
      child: DropdownButton<String>(
        value: _selectedAssessment,
        icon: Icon(Icons.arrow_downward, color: Colors.white),
        iconSize: 24,
        elevation: 16,
        style: TextStyle(color: Colors.white),
        underline: Container(
          height: 2,
          color: Colors.white,
        ),
        onChanged: (String? newValue) {
          setState(() {
            _selectedAssessment = newValue!;
          });
        },
        items: _assessments.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: TextStyle(color: Colors.white)),
          );
        }).toList(),
      ),
    );
  }
}

class DepartmentDropdown extends StatefulWidget {
  @override
  _DepartmentDropdownState createState() => _DepartmentDropdownState();
}

class _DepartmentDropdownState extends State<DepartmentDropdown> {
  String _selectedDepartment = 'Select department';
  final List<String> _departments = [
    'Select department',
    'Artificial Intelligence and Data Science',
    'Civil Engineering',
    'Computer Science and Business Systems',
    'Computer Science and Design',
    'Computer Science and Engineering',
    'Electrical and Electronics Engineering',
    'Electronics and Communication Engineering',
    'Electronics and Communication (Advanced Communication Technology)',
    'Electronics Engineering (VLSI Design and Technology)',
    'Electronics and Instrumentation Engineering',
    'Information Technology',
    'Mechanical Engineering',
    'Science and Humanities',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: EdgeInsets.all(16),
      width: double.infinity,
      child: DropdownButton<String>(
        value: _selectedDepartment,
        icon: Icon(Icons.arrow_downward, color: Colors.white),
        iconSize: 24,
        elevation: 16,
        style: TextStyle(color: Colors.white),
        underline: Container(
          height: 2,
          color: Colors.white,
        ),
        onChanged: (String? newValue) {
          setState(() {
            _selectedDepartment = newValue!;
          });
        },
        items: _departments.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: TextStyle(color: Colors.white)),
          );
        }).toList(),
      ),
    );
  }
}

class ResultBuzzPage extends StatefulWidget {
  @override
  _ResultBuzzPageState createState() => _ResultBuzzPageState();
}

class _ResultBuzzPageState extends State<ResultBuzzPage> {
  String? filePath;
  int noOfEntries = 0;
  int validContacts = 0;
  int totalbatch = 0;
  int batchstatus = 0;
  bool isSending = false;
  bool enableSend = true;

  final Telephony telephony = Telephony.instance;
  List<Map<String, String>> phoneMessages = [];
  int currentBatch = 0;
  int totalBatches = 0;
  List<String> invalidNumbers = [];

  // Function to pick the file
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        filePath = result.files.single.path;
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
      List<String> InvalidNos = [];
      List<String> columnNames = [];

      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet != null) {
          for (var rowIndex = 0; rowIndex < sheet.rows.length; rowIndex++) {
            var row = sheet.rows[rowIndex];
            if (rowIndex == 0) {
              columnNames = row.map((e) => e?.value.toString() ?? '').toList();
              if (!columnNames.contains('phone') &&
                  !columnNames.contains('phone number') &&
                  !columnNames.contains("parent number")) {
                File(filePath).delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'The file does not contain a "phone" column and has been deleted.')),
                );
                return;
              }
            } else {
              if (row.isNotEmpty && row[0] != null) {
                Map<String, String> rowMap = {};
                for (var i = 0; i < row.length; i++) {
                  if (i == 0 && row[0]!.value.toString().length != 10) {
                    InvalidNos.add(row[0]!.value.toString());
                  }
                  rowMap[columnNames[i]] = row[i]?.value.toString() ?? '';
                }
                if (rowMap['phone']?.isNotEmpty == true) {
                  String formattedMessage = rowMap.entries
                      .where((e) => e.key != 'phone' && e.key != 'null')
                      .map((e) => '${e.key as String} : ${e.value as String}')
                      .join('\n');
                  tempPhoneMessages.add({
                    'phone': rowMap['phone']!,
                    'message': formattedMessage,
                  });
                }
              }
            }
          }
        }
      }

      setState(() {
        phoneMessages = tempPhoneMessages;
        totalBatches =
            (phoneMessages.length / 5).ceil(); // Calculate total batches
        currentBatch = 0;
        noOfEntries = phoneMessages.length;
        validContacts = phoneMessages.length - InvalidNos.length;
        totalbatch = totalBatches;
        batchstatus = currentBatch;
        invalidNumbers = InvalidNos;
        enableSend = InvalidNos.isEmpty;
      });
      if (InvalidNos.isNotEmpty) {
        showErrorDialog("Sorry Numbers are invalid", InvalidNos);
      }
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
    const delay = Duration(seconds: 10);

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
        final finalmessage = "RMKEC RESULT";
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
        batchstatus = currentBatch;
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

  void showErrorDialog(String message, List<String> invalidNumbers) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invalid Numbers Exist'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              SizedBox(height: 10),
              ...invalidNumbers.map((number) => Text(number)).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 600 ? 4 : 2;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF164863),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.jpg',
                height: 40,
              ),
              SizedBox(width: 10),
              Text(
                'R.M.K. Engineering College',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2C5364), Color(0xFF203A43), Color(0xFF0F2027)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Welcome Counsellor',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "Let's send result to parents",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.all(16),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Result Buzz',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: pickFile,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Color(0xFF164863),
                            backgroundColor: Colors.white,
                          ),
                          child: Text(
                            'Upload File',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                        if (filePath != null) ...[
                          SizedBox(height: 10),
                          Text(
                            'Selected File: ${filePath!.split('/').last}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ]
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  DepartmentDropdown(),
                  AssessmentDropdown(),
                  SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      InfoCard(
                        title: 'No of Entries',
                        value: noOfEntries.toString(),
                      ),
                      InfoCard(
                        title: 'Valid Contacts',
                        value: validContacts.toString(),
                      ),
                      InfoCard(
                        title: 'Total Batches',
                        value: totalbatch.toString(),
                      ),
                      InfoCard(
                        title: 'Batch Status',
                        value: '$batchstatus/$totalbatch',
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (isSending)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(
                            height:
                                16), // Space between the progress indicator and the text
                        Text(
                          'Current Batch $currentBatch of $totalBatches',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  if (!isSending)
                    if (enableSend)
                      (ElevatedButton(
                        onPressed: handleSendSMS,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Color(0xFF164863),
                          backgroundColor: Colors.white,
                        ),
                        child: Text(
                          'Send SMS',
                          style: TextStyle(fontSize: 15),
                        ),
                      ))
                    else
                      Text("Fix The Invalid Numbers",
                          style: TextStyle(
                              color: Color.fromARGB(255, 247, 1, 1),
                              fontSize: 24)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
