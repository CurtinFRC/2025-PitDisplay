import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pit_display/model/match.dart';
import 'package:pit_display/services/tba_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';



class MatchScheduleCache {
  static final MatchScheduleCache _instance = MatchScheduleCache._internal();
  factory MatchScheduleCache() => _instance;
  MatchScheduleCache._internal();

  List<Match>? _cachedMatches;
  DateTime? _lastUpdateTime;

  List<Match>? get cachedMatches => _cachedMatches;
  DateTime? get lastUpdateTime => _lastUpdateTime;

  void updateCache(List<Match> matches) {
    _cachedMatches = matches;
    _lastUpdateTime = DateTime.now();
  }

  bool isCacheValid() => _lastUpdateTime != null && 
    DateTime.now().difference(_lastUpdateTime!).inMinutes < 5; // Cache valid for 5 minutes
}

class MatchSchedule extends StatefulWidget {
  const MatchSchedule({super.key});
  
  @override
  State<MatchSchedule> createState() => _MatchScheduleState();
}

class _MatchScheduleState extends State<MatchSchedule> 
    with AutomaticKeepAliveClientMixin { // Add state preservation mixin
  
  Logger logger = Logger();
  final ScrollController _controller = ScrollController();
  List<Match> _matches = [];
  late Timer _apiTimer;
  SharedPreferences? _prefs;

  @override
  bool get wantKeepAlive => true; // Enable state preservation

  @override
  void initState() {
    super.initState();
    
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });

    // Try to use cached data first
    final cache = MatchScheduleCache();
    if (cache.isCacheValid()) {
      setState(() {
        _matches = cache.cachedMatches ?? [];
      });
    } else {
      _getMatchSchedule();
    }

    _apiTimer = Timer.periodic(
      const Duration(seconds: 10), 
      (timer) => _getMatchSchedule()
    );
  }

  @override 
  void dispose() {    
    _apiTimer.cancel();
    super.dispose();
  }

  Future<void> _getMatchSchedule() async {
    try {
      final matches = await TBA.getTeamMatchSchedule();
      
      if (matches == null) {
        logger.e("no matches found in getMatchSchedule");
        setState(() {
          _matches = [];
        });
      } else {
        setState(() {
          _matches = matches;
        });
        // Update cache
        MatchScheduleCache().updateCache(matches);
      }

      Future.delayed(const Duration(milliseconds: 100),
        () => _controller.jumpTo(_controller.position.maxScrollExtent));
    } catch (err) {
      if (kDebugMode) {
        logger.e('TBA API err: $err');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: ListView(
    controller: _controller,
    children: [
      Text("Match Schedule", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      if (_matches.isEmpty)
        Text("No matches available.", style: TextStyle(fontSize: 18, color: Colors.red)),
      for (Match match in _matches)
        (match is FinishedMatch)
          ? _finishedMatchTile(match, context)
          : _upcomingMatchTile(match as UpcomingMatch, context),
    ],
    ),
  );
  }

  // void _getMatchSchedule() {
  // TBA.getTeamMatchSchedule().then((matches) {
  //   if (matches == null) {
  //     logger.e("no matches found in getMatchSchedule");
  //     setState(() {
  //       _matches = [];
  //     });
  //   } else {
  //     setState(() {
  //       _matches = matches;
  //     });
  //   }

  //   Future.delayed(const Duration(milliseconds: 100),
  //     () => _controller.jumpTo(_controller.position.maxScrollExtent));
  // }).catchError((err) {
  //   if (kDebugMode) {
  //     logger.e('TBA API err: $err');
  //   }
  // });
  // }


  Widget _upcomingMatchTile(UpcomingMatch match, BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    int etaMinutes =
      (match.estimatedStartTime.difference(DateTime.now()).inSeconds / 60)
        .round();

    return Card(
      color: (match.weAreRed ?? false)
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer,
      child: ListTile(
      leading: Text(match.matchNumber),
      title: Row(
        children: [
        SizedBox(
          width: 48,
          child: Center(
          child: _teamNumber(match.redTeams[0], colorScheme.error),
          ),
        ),
        SizedBox(
          width: 48,
          child: Center(
          child: _teamNumber(match.redTeams[1], colorScheme.error),
          ),
        ),
        SizedBox(
          width: 48,
          child: Center(
          child: _teamNumber(match.redTeams[2], colorScheme.error),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 48,
          child: Center(
          child: _teamNumber(match.blueTeams[0], colorScheme.primary),
          ),
        ),
        SizedBox(
          width: 48,
          child: Center(
          child: _teamNumber(match.blueTeams[1], colorScheme.primary),
          ),
        ),
        SizedBox(
          width: 48,
          child: Center(
          child: _teamNumber(match.blueTeams[2], colorScheme.primary),
          ),
        ),
        SizedBox(
          width: 600,
          child: Center(
          child: Text(
            'Statbotics Prediction: Win Percent: ${((match.weAreRed != null) ? (match.weAreRed! ? match.statboticsPred.toString() : 100 - match.statboticsPred) : "Statbotics Err")}',
            textScaler: const TextScaler.linear(0.5),
          ),
          ),
        ),
        ],
      ),
      trailing: SizedBox(
        width: 110,
        child: Center(
        child: etaMinutes <= 3
          ? const Text('<3m')
          : Text(etaMinutes < 60
            ? '~${etaMinutes}m'
            : '~${(etaMinutes / 60).floor()}:${(etaMinutes % 60).toString().padLeft(2, '0')}'),
        ),
      ),
      ),
    );
  }

  Widget _finishedMatchTile(FinishedMatch match, BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    Color? outcomeColor;
    if (match.outcome != Outcome.tie) {
      if (match.outcome == Outcome.redWin && (match.weAreRed ?? false)) {
      outcomeColor = Colors.green;
      } else if (match.outcome == Outcome.blueWin &&
        !(match.weAreRed ?? false)) {
      outcomeColor = Colors.green;
      } else {
      outcomeColor = Colors.red;
      }
    }

    return Card(
      child: ListTile(
      leading: Text(
        (match.redRP == 0 && match.blueRP == 0)
          ? match.matchNumber
          : ((match.weAreRed ?? false)
            ? '${match.redRP}RP'
            : '${match.blueRP}RP'),
        style: TextStyle(color: outcomeColor),
      ),
      title: Row(
        children: [
        SizedBox(
          width: 48,
          child: Center(
          child: _teamNumber(match.redTeams[0], colorScheme.error),
          ),
        ),
        SizedBox(
          width: 48,
          child: Center(
          child: _teamNumber(match.redTeams[1], colorScheme.error),
          ),
        ),
        SizedBox(
          width: 48,
          child: Center(
          child: _teamNumber(match.redTeams[2], colorScheme.error),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 48,
          child: Center(
          child: _teamNumber(match.blueTeams[0], colorScheme.primary),
          ),
        ),
        SizedBox(
          width: 48,
          child: Center(
          child: _teamNumber(match.blueTeams[1], colorScheme.primary),
          ),
        ),
        SizedBox(
          width: 48,
          child: Center(
          child: _teamNumber(match.blueTeams[2], colorScheme.primary),
          ),
        ),
        ],
      ),
      trailing: SizedBox(
        width: 110,
        child: Row(
        children: [
          SizedBox(
          width: 48,
          child: Center(
            child: Text(
            match.redScore.toString(),
            style: TextStyle(color: colorScheme.error),
            ),
          ),
          ),
          const Text('-'),
          SizedBox(
          width: 48,
          child: Center(
            child: Text(
            match.blueScore.toString(),
            style: TextStyle(color: colorScheme.primary),
            ),
          ),
          ),
        ],
        ),
      ),
      ),
    );
  }


  Widget _teamNumber(int team, Color color) {
  return Text(
    team.toString(),
    style: TextStyle(
    color: color,
    decoration: (team == _prefs?.getInt('teamNumber'))
      ? TextDecoration.underline
      : null,
    ),
  );
  }
}