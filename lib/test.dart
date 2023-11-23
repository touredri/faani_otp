import 'package:background_sms/background_sms.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/firebase_options.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:math';

@pragma('vm:entry-point')
void callbackDispatcher() {
  // WidgetsFlutterBinding.ensureInitialized();
  print("Sending SMS to with code----------------callback-1--------"); // not printed

  Workmanager().executeTask((task, inputData) async {
    print("Dans le callback dispatcher----------------callback-2--------"); // not printed
    int? totalExecutions;
    final _sharedPreference =
        await SharedPreferences.getInstance(); //Initialize dependency
    try {
      //add code execution
      print("inside workmanager---------------------Wormanager-Inside----"); // not printed
      if (inputData != null) {
        var numero = inputData['numero'] as String;
        var code = inputData['code'] as String;
        print(
            "Sending SMS to $numero with code $code for ---------------callback-3--------"); // not printed
        // Call _sendMessage to send SMS and handle document deletion
        _sendMessage(numero, code);
      } else {
        print("No input data found ---------------callback-4--------"); // not printed
      }
    } catch (err) {
      Logger().e(err
          .toString()); // Logger flutter package, prints error on the debug console
      throw Exception(err);
    }
    return Future.value(true);
  });
}

Future<void> start() async {
  if (await _isPermissionGranted()) {
    FirebaseFirestore.instance.collection('OTP').snapshots().listen((snapshot) {
      print(
          "Il y'a eu ${snapshot.docChanges.length} changement-------------Start-1-----------");
      for (var change in snapshot.docChanges) {
        print('$change------------start-2----------------------');
        if (change.type == DocumentChangeType.added) {
          print("Document added to collection----------------start-3--------------");
          var numero = change.doc['numero'] as String;
          var code = change.doc['code'] as String;
          print(
              "Number is $numero with code $code------------start-4------------------");

          var taskId = change.doc.id;
          // Register the task with the input data
          Workmanager().registerOneOffTask(
            taskId,
            "simpleTask",
            inputData: <String, dynamic>{
              'numero': numero,
              'code': code,
            },
          );
        }
      }
    });
  } else {
    _getPermission();
  }
}

int getRandomNumber() {
  var random = Random();
  return random.nextInt(100);  // Génère un nombre aléatoire entre 0 et 99
}

Future<void> _sendMessage(String phoneNumber, String message) async {
  // Immediately send the SMS
  print("Sending SMS");
  var result = await BackgroundSms.sendMessage(
      phoneNumber: phoneNumber, message: message, simSlot: 1);
  if (result == SmsStatus.sent) {
    print("Sent");
    await _deleteDocument(phoneNumber);
  } else {
    print("Failed");
    // Handle failure (e.g., show a notification)
  }
}

Future<void> _deleteDocument(String phoneNumber) async {
  await Firebase.initializeApp();
  try {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('OTP')
        .where('numero', isEqualTo: phoneNumber)
        .get();
    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  } catch (error) {
    print("Failed to delete document: $error");
  }
}

Future<void> _getPermission() async {
  await Permission.sms.request();
}

Future<bool> _isPermissionGranted() async {
  return await Permission.sms.status.isGranted;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await start();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // _getPermission() async => await [
  //       Permission.sms,
  //     ].request();

  // Future<bool> _isPermissionGranted() async =>
  //     await Permission.sms.status.isGranted;

  // @override
  // void initState() {
  //   super.initState();
  //   start();
  // }

  // void start() async {
  //   if (await _isPermissionGranted()) {
  //     FirebaseFirestore.instance
  //         .collection('OTP')
  //         .snapshots()
  //         .listen((snapshot) {
  //       for (var change in snapshot.docChanges) {
  //         if (change.type == DocumentChangeType.added) {
  //           var numero = change.doc['numero'] as String;
  //           var code = change.doc['code'] as String;
  //           Workmanager().registerOneOffTask(
  //             "1",
  //             "simpleTask",
  //             inputData: <String, dynamic>{
  //               'numero': numero,
  //               'code': code,
  //             },
  //           );
  //         }
  //       }
  //     });
  //   } else {
  //     _getPermission();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Send Sms'),
        ),
      ),
    );
  }
}
