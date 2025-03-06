import 'package:flutter/material.dart';
// import 'package:nt4/nt4.dart';
// import 'package:logger/logger.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:pit_display/pages/match_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    center: true,
    title: 'Pit Display',
    size: Platform.isWindows
      ? const Size(1936, 1119)
      : Platform.isMacOS
        ? const Size(1512, 982) // fullscreen for 14 inch macbook pro (dev machine)
        : const Size(1920, 1145), // Equivalent of 1920 1080 when fullscreen
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt('teamNumber', 4788);
  await prefs.setString('eventKey', '2025ausc');

  MatchDataService().initialize();

  runApp(const PitDisplay());
}

class PitDisplay extends StatelessWidget {
  const PitDisplay({super.key});

  void dispose() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 2, // Number of tabs
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.pinkAccent,
            title: const Text('4788 Pit Display'),
            bottom: const TabBar(
              tabs: [
                Tab(text: "Matches"),
                Tab(text: "Impact"),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              MatchSchedule(),
              Container(color: Colors.white, child: Image(image: AssetImage('assets/impact.png'))),
            ],
          ),
        ),
      ),
    );
  }
}

// void networkTables() async {
//   var logger = Logger();
//   // Connect to NT4 server at 10.47.88.2
//   NT4Client client = NT4Client(
//     serverBaseAddress: '10.47.88.2',
//     onConnect: () {
//       logger.i('\nNT4 Client Connected\n');
//     },
//     onDisconnect: () {
//       logger.w('\nNT4 Client Disconnected\n');
//     },
//   );

//   // Subscribe to a topic
//   NT4Subscription exampleSub =
//       client.subscribePeriodic('/SmartDashboard/DB/Slider 0');

//   // Recieve data from subscription with a callback or stream
//   exampleSub.listen((data) => logger.i('Recieved data from callback: $data'));

//   await for (Object? data in exampleSub.stream()) {
//     logger.i('Recieved data from stream: $data');
//   }
// }