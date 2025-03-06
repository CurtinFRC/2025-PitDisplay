import 'package:flutter/material.dart';
import 'package:pit_display/model/match.dart';
import 'package:pit_display/styles/colours.dart';
import 'dart:async';
import 'package:logger/logger.dart';



class UpcomingMatchTile extends StatefulWidget {
  final UpcomingMatch match;
  final BuildContext context;

  const UpcomingMatchTile({
    super.key,
    required this.match,
    required this.context,
  });

  @override
  UpcomingMatchTileState createState() => UpcomingMatchTileState();
}

class UpcomingMatchTileState extends State<UpcomingMatchTile> {
  String? estimatedStartTime;
  Timer? timer;
  int? winChance;

  var logger = Logger();
  String _getWinChance() {
    if (widget.match.statboticsPred != null) {
      if (widget.match.weAreRed == false) {
        return "${(100 - (widget.match.statboticsPred!)).toString()}%";
      } else {
        return "${widget.match.statboticsPred.toString()}%";
      }
    } else {
      return "not found";
    }
  }

  void _updateEstimatedTime() {
    setState(() {
      if (widget.match.estimatedStartTime.isBefore(DateTime.now())) {
        estimatedStartTime = "Now";
      } else {
        if (widget.match.estimatedStartTime.difference(DateTime.now()).inMinutes < 60) {
          int minutes = widget.match.estimatedStartTime.difference(DateTime.now()).inMinutes;
          estimatedStartTime = "~$minutes min";
        } else {
          if (widget.match.estimatedStartTime.difference(DateTime.now()).inHours < 2) {
            int hours = widget.match.estimatedStartTime.difference(DateTime.now()).inHours;
            int minutes = widget.match.estimatedStartTime.difference(DateTime.now()).inMinutes % 60;
            estimatedStartTime = "~${hours}h ${minutes.toString().padLeft(2, '0')}m";
          } else {
            estimatedStartTime = widget.match.estimatedStartTime.toLocal().toString().substring(0, 16);
          }
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _updateEstimatedTime(); // Initial update
    timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateEstimatedTime(),
    );
  }

  @override
  void dispose() {
    timer?.cancel(); // Clean up the timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Card(
        child: Row(
          children: [
            Spacer(flex: 1),
            Text(widget.match.matchNumber),
            Spacer(flex: 1),
            _alliances(widget.match),
            Spacer(flex: 2),
            Text(_getWinChance()),
            Spacer(flex: 2),
            SizedBox(
              width: 90,
              child: Center(child: Text(estimatedStartTime ?? '', textAlign: TextAlign.center)),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget upcomingMatchTile(UpcomingMatch match, BuildContext context) {
//   String estimatedStartTime;
//   if (match.estimatedStartTime.isBefore(DateTime.now())) {
//     estimatedStartTime = "Now";
//   } else {
//     if (match.estimatedStartTime.difference(DateTime.now()).inMinutes < 60) {
//       int minutes = match.estimatedStartTime.difference(DateTime.now()).inMinutes;
//       estimatedStartTime = "~$minutes min";
//     } else {
//     if (match.estimatedStartTime.difference(DateTime.now()).inHours < 2) {
//       int hours = match.estimatedStartTime.difference(DateTime.now()).inHours;
//       int minutes = match.estimatedStartTime.difference(DateTime.now()).inMinutes % 60;
//       estimatedStartTime = "~${hours}h ${minutes.toString().padLeft(2, '0')}m";
//     } else {
//       estimatedStartTime = match.estimatedStartTime.toLocal().toString().substring(0, 16);
//     }
//     }
//   }

//   return SizedBox(
//     height: 60,
//     child: Card(
//       child: Row(
//         children: [
//           Spacer(flex: 1),
//           Text(match.matchNumber),
//           Spacer(flex: 1),
//           _alliances(match),
//           Spacer(flex: 2),
//           Text("${match.statboticsPred}%"),
//           Spacer(flex: 2),
//           SizedBox(
//             width: 90,
//             child: Center(child: Text(estimatedStartTime, textAlign: TextAlign.center,)),
//           ),
//         ],
//       ),
//     ),
//   );
// }

Widget finishedMatchTile(FinishedMatch match, BuildContext context) {
  return SizedBox(
    height: 60,
      child: Card(
      child: Row(
        children: [
          Spacer(flex: 1),
          Text(match.matchNumber),
          Spacer(flex: 2),
          _alliances(match),
          Spacer(flex: 4),
          Text(match.actualTime.toLocal().toString().substring(0, 16)),
          Spacer(flex: 4),
          SizedBox(
            width: 110,
            child: Row(
              children: [
                SizedBox(
                width: 48,
                  child: Center(
                    child: Text(
                      match.redScore.toString(),
                      style: TextStyle(
                        color: AppColours.firstRed,
                        fontWeight: (match.weAreRed ?? false)
                          ? FontWeight.w900
                          : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const Text('-'),
                SizedBox(
                  width: 48,
                  child: Center(
                    child: Text(
                      match.blueScore.toString(),
                      style: TextStyle(
                        color: AppColours.firstBlue,
                        fontWeight: !(match.weAreRed ?? false)
                          ? FontWeight.w900
                          : FontWeight.normal,
                      )
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
  );
}

Widget nextMatchTile(List<Match> matches, BuildContext context) {

  if (matches.isEmpty) {
    return const Card();
  }

  int? upcomingMatchIndex;
  for (int i = 0; i < matches.length; i++) {
    if (matches[i] is UpcomingMatch) {      // change to UpcomingMatch when new data is available
      upcomingMatchIndex = i;
      break;
    }
  }
  
  if (upcomingMatchIndex == null) {
    return const Card();
  }

  String getWinChance() {
    if ((matches[upcomingMatchIndex!] as UpcomingMatch).statboticsPred != null) {
      if (matches[upcomingMatchIndex].weAreRed == false) {
        return "${(100 - ((matches[upcomingMatchIndex] as UpcomingMatch).statboticsPred!)).toString()}%";
      } else {
        return "${(matches[upcomingMatchIndex] as UpcomingMatch).statboticsPred.toString()}%";
      }
    } else {
      return "not found";
    }
  }

  UpcomingMatch upcomingMatch = matches[upcomingMatchIndex] as UpcomingMatch;

  String estimatedStartTime;
  if (upcomingMatch.estimatedStartTime.isBefore(DateTime.now())) {
      estimatedStartTime = "Now";
  } else {
    if (upcomingMatch.estimatedStartTime.difference(DateTime.now()).inMinutes < 60) {
      int minutes = upcomingMatch.estimatedStartTime.difference(DateTime.now()).inMinutes;
      estimatedStartTime = "~$minutes min";
    } else {
      int hours = upcomingMatch.estimatedStartTime.difference(DateTime.now()).inHours;
      int minutes = upcomingMatch.estimatedStartTime.difference(DateTime.now()).inMinutes % 60;
      estimatedStartTime = "~${hours}h ${minutes.toString().padLeft(2, '0')}m";
    }
  }


  return SizedBox(
    height: 60,
    child: Card(
      child: Column (
        children: [
          Center(child: Text("Next Match", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          Spacer(flex: 3),
          Row (
            children: [
              Spacer(flex: 1),
              Text("Match", style: TextStyle(fontWeight: FontWeight.bold)),
              Spacer(flex: 10),
              Text("Red Alliance", style: TextStyle(fontWeight: FontWeight.bold)),
              Spacer(flex: 4),
              Text("Blue Alliance", style: TextStyle(fontWeight: FontWeight.bold)),
              Spacer(flex: 16),
              Text("Estimated Start Time", style: TextStyle(fontWeight: FontWeight.bold)),
              Spacer(flex: 10),
              Text("Estimated Win Chance", style: TextStyle(fontWeight: FontWeight.bold)),
              Spacer(flex: 1),
            ],
          ),
          Spacer(),
          Row(
            children: [
              Spacer(flex: 3),
              Text(upcomingMatch.matchNumber),
              Spacer(flex: 20),
              _alliances(upcomingMatch),
              Spacer(flex: 38),
              Text(estimatedStartTime),
              Spacer(flex: 34),
              // Text((matches[upcomingMatchIndex] as UpcomingMatch).statboticsPred != null ? getWinChance() : "not found"),
              Text(getWinChance()),
              Spacer(flex: 8)
            ],
          ),
        ]
      )
    ),
  );
}

Widget finishedHeaderTile() {
  return SizedBox(
    height: 20,
    child: Row(
      children: [
        Spacer(flex: 4),
        Text("Match", style: TextStyle(fontWeight: FontWeight.bold)),
        Spacer(flex: 10),
        Text("Red Alliance", style: TextStyle(fontWeight: FontWeight.bold)),
        Spacer(flex: 21),
        Text("Blue Alliance", style: TextStyle(fontWeight: FontWeight.bold)),
        Spacer(flex: 34),
        Text("Time", style: TextStyle(fontWeight: FontWeight.bold)),
        Spacer(flex: 38),
        Text("Score", style: TextStyle(fontWeight: FontWeight.bold)),
        Spacer(flex: 12),
      ],
    ),
  );
}

Widget upcomingHeaderTile() {
  return SizedBox(
    height: 20,
    child: Row(
      children: [
        Spacer(flex: 1),
        Text("Match", style: TextStyle(fontWeight: FontWeight.bold)),
        Spacer(flex: 2),
        Text("Red Alliance", style: TextStyle(fontWeight: FontWeight.bold)),
        Spacer(flex: 2),
        Text("Blue Alliance", style: TextStyle(fontWeight: FontWeight.bold)),
        Spacer(flex: 1),
        Text("Estimated Win Chance", style: TextStyle(fontWeight: FontWeight.bold)),
        Spacer(flex: 1),
        Text("ETA", style: TextStyle(fontWeight: FontWeight.bold)),
        Spacer(flex: 1),
      ],
    ),
  );
}



Widget _teamNumber(int team, Color colour, bool weAreRed) {
  return Text(
    team.toString(),
    style: TextStyle(
      color: colour,
      fontWeight: (colour == AppColours.firstRed && weAreRed) || (colour == AppColours.firstBlue && !weAreRed)
        ? FontWeight.w800
        : FontWeight.normal,
    ),
  );
}

Widget _alliances(Match match) {
  return Row(
    children: [
      Row (
        children: [
          SizedBox(
            width: 52,
            child: Center(
            child: _teamNumber(match.redTeams[0], AppColours.firstRed, match.weAreRed ?? false),
            ),
          ),
          SizedBox(
            width: 52,
            child: Center(
              child: _teamNumber(match.redTeams[1], AppColours.firstRed, match.weAreRed ?? false),
            ),
          ),
          SizedBox(
            width: 52,
            child: Center(
            child: _teamNumber(match.redTeams[2], AppColours.firstRed, match.weAreRed ?? false),
            ),
          ),
        ],
      ),
      const SizedBox(width: 20),
      Row (
        children: [
          SizedBox(
            width: 52,
            child: Center(
            child: _teamNumber(match.blueTeams[0], AppColours.firstBlue, match.weAreRed ?? false),
            ),
          ),
          SizedBox(
            width: 52,
            child: Center(
            child: _teamNumber(match.blueTeams[1], AppColours.firstBlue, match.weAreRed ?? false),
            ),
          ),
          SizedBox(
            width: 52,
            child: Center(
            child: _teamNumber(match.blueTeams[2], AppColours.firstBlue, match.weAreRed ?? false),
            ),
          ),
        ],
      ),
    ],
  );
}