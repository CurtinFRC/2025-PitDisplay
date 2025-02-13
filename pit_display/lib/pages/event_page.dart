import "package:pit_display/events/match_schedule.dart";
import 'package:flutter/material.dart';

class EventPage extends StatelessWidget {
  const EventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text('Event Page'),
      ),
      body: MatchSchedule(),
    );
  }
}
