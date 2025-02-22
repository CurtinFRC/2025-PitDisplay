import "package:pit_display/widgets/match_schedule.dart";
import 'package:flutter/material.dart';

class EventPage extends StatelessWidget {
  const EventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MatchSchedule(),
    );
  }
}
