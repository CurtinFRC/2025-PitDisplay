import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pit_display/model/match.dart';
import 'package:pit_display/services/tba_api.dart';
import 'package:logger/logger.dart';
import 'package:pit_display/widgets/match_tiles.dart';

class MatchDataService {
  static final MatchDataService _instance = MatchDataService._internal();
  factory MatchDataService() => _instance;
  MatchDataService._internal();

  final MatchScheduleCache _cache = MatchScheduleCache();
  bool _hasLoadedOnce = true;

  Future<void> initialize() async {
    _hasLoadedOnce = false;
    if (_hasLoadedOnce) return;
    try {
      await _loadData();
    } finally {
      _hasLoadedOnce = true;
    }
  }

  Future<void> _loadData() async {
    final matches = await TBA.getTeamMatchSchedule();
    if (matches != null) {
      _cache.updateCache(matches);
    }
    _hasLoadedOnce = true;
  }
  bool get hasLoadedOnce => _hasLoadedOnce;
}

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
  final ScrollController _pastMatchScrollController = ScrollController();
  final ScrollController _upcomingMatchScrollController = ScrollController();
  List<Match> _matches = [];
  late Timer _apiTimer;

  @override
  bool get wantKeepAlive => true; // Enable state preservation

  @override
  void initState() {
    super.initState();

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
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    List<UpcomingMatch> upcomingMatches = [];
    bool hasUpcomingMatches = false;
    if (_matches.isNotEmpty) {
      upcomingMatches = _matches.whereType<UpcomingMatch>().toList();
      if (upcomingMatches.isNotEmpty) {
        hasUpcomingMatches = true;
        upcomingMatches.removeAt(0);    // remove the next match as it will be displayed separately
      }
    }
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (!MatchDataService().hasLoadedOnce)
            Container(
              alignment: Alignment.center,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          if (MatchDataService().hasLoadedOnce && _matches.isEmpty)
            const Text(
              "No matches available.",
              style: TextStyle(
                fontSize: 18,
                color: Colors.red,
              ),
            ),
          if (_matches.isNotEmpty)   
            if (hasUpcomingMatches)
              Expanded(flex: 1, child: nextMatchTile(_matches, context)),
            Expanded(
              flex: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text("Upcoming Matches", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(height: 10),
                        upcomingHeaderTile(),
                        Expanded(
                          child: Container(
                            margin:  const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.only(top: 8),
                            child: ListView(
                              controller: _upcomingMatchScrollController,
                              children: [
                                for (UpcomingMatch match in upcomingMatches)
                                  upcomingMatchTile(match, context),
                              ],
                            ),
                          )
                        ),
                      ],
                    ),
                  ),
                  Container(    // Vertical divider
                    width: 2,
                    color: Colors.black,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text("Past Matches", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(height: 10),
                        finishedHeaderTile(),
                        Expanded(
                          child: Container(
                            margin:  const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.only(top: 8),
                            child: ListView(
                              controller: _pastMatchScrollController,
                              children: [
                                for (Match match in _matches.reversed)
                                  if (match is FinishedMatch)
                                  finishedMatchTile(match, context),
                              ],
                            ),
                          )
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ),
        ],
      ),
    );
  }
}