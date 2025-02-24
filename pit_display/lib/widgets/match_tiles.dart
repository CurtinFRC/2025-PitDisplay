import 'package:flutter/material.dart';
import 'package:pit_display/model/match.dart';
// import 'package:logger/logger.dart';
import 'package:pit_display/styles/colours.dart';

Widget upcomingMatchTile(UpcomingMatch match, BuildContext context) {

  
  int etaMinutes =
    (match.estimatedStartTime.difference(DateTime.now()).inSeconds / 60)
      .round();

  return Card(
    color: (match.weAreRed ?? false)
      ? AppColours.firstRed
      : AppColours.firstBlue,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(40), // if you need this
      side: BorderSide(
        color: Colors.grey.withOpacity(0.2),
        width: 1,
      ),
    ),
    child: ListTile(
      leading: Text(match.matchNumber),
      title: _alliances(match),
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

Widget finishedMatchTile(FinishedMatch match, BuildContext context) {
  return SizedBox(
    height: 60,
      child: Card(
      // shape: RoundedRectangleBorder(     // uncomment this to add border
      //   side: BorderSide(
      //     color: (match.weAreRed ?? false)
      //       ? AppColours.firstRed
      //       : AppColours.firstBlue,
      //     width: 2,
      //   ),
      //   borderRadius: BorderRadius.circular(10.0),
      // ),
      child: Row(
        children: [
          Spacer(flex: 1),
          Text(match.matchNumber),
          Spacer(flex: 2),
          _alliances(match),
          Spacer(flex: 4),
          Text(match.actualTime.toString().substring(0, 16)),
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

  UpcomingMatch upcomingMatch = matches[upcomingMatchIndex] as UpcomingMatch;
  return SizedBox(
    height: 60,
    child: Card(
      child: Column (
        children: [
          Row (
            children: [
              Spacer(flex: 1),
              Text("Next Match"),
              Spacer(flex: 18),
              Text("Red Alliance"),
              Spacer(flex: 7),
              Text("Blue Alliance"),
              Spacer(flex: 20),
              Text("Estimated Start Time"),
              Spacer(flex: 20),
              Text("StatBotics Pred Red Win %"),
            ],
          ),
          Spacer(),
          Row(
            children: [
              Spacer(flex: 3),
              Text(upcomingMatch.matchNumber,),
              Spacer(flex: 20),
              _alliances(upcomingMatch),
              Spacer(flex: 40),
              Text(upcomingMatch.estimatedStartTime.toString().substring(0, 16)),
              Spacer(flex: 40),
              Text("${upcomingMatch.statboticsPred}%"),
            ],
          ),
        ]
      )
    ),
  );
}

Widget headerTile() {
  return SizedBox(
    height: 15,
    // shape: RoundedRectangleBorder(   // uncomment this to add border
    //   side: BorderSide(
    //     color: Colors.black,
    //     width: 1.5,
    //   ),
    //   borderRadius: BorderRadius.circular(10.0),
    // ),
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


Widget _teamNumber(int team, Color colour) {
  return Text(
    team.toString(),
    style: TextStyle(
      color: colour,
      // decoration: (team == prefs?.getInt('teamNumber'))
      //   ? TextDecoration.underline
      //   : null,
      fontWeight: (team == 4788)
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
            width: 48,
            child: Center(
            child: _teamNumber(match.redTeams[0], AppColours.firstRed),
            ),
          ),
          SizedBox(
            width: 48,
            child: Center(
              child: _teamNumber(match.redTeams[1], AppColours.firstRed),
            ),
          ),
          SizedBox(
            width: 48,
            child: Center(
            child: _teamNumber(match.redTeams[2], AppColours.firstRed),
            ),
          ),
        ],
      ),
      const SizedBox(width: 16),
      Row (
        children: [
          SizedBox(
            width: 48,
            child: Center(
            child: _teamNumber(match.blueTeams[0], AppColours.firstBlue),
            ),
          ),
          SizedBox(
            width: 48,
            child: Center(
            child: _teamNumber(match.blueTeams[1], AppColours.firstBlue),
            ),
          ),
          SizedBox(
            width: 48,
            child: Center(
            child: _teamNumber(match.blueTeams[2], AppColours.firstBlue),
            ),
          ),
        ],
      ),
    ],
  );
}