import 'dart:convert';    // for managing JSON data

import 'package:http/http.dart' as http;
import 'package:pit_display/model/match.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TBA {
  static final Future<String> _apiKey = getTBAAuthKey(); 
  
  static SharedPreferences? _prefs;

  static Future<Map<String, dynamic>?> getTeamRankingData() async {
    _prefs ??= await SharedPreferences.getInstance();

    int team = _prefs?.getInt('teamNumber') ?? 4788;
    String event = _prefs?.getString('eventKey') ?? '2024ausc';   // 2025ausc is the event key for the 2025 Australian Southern Cross Regional

   var url = Uri.parse(
        'https://www.thebluealliance.com/api/v3/team/$team/event/$event/status');
    var response = await http.get(url,
        headers: {'accept': 'application/json', 'X-TBA-Auth-Key': await _apiKey}); 

    if (response.body == 'null') {
      return null;
    }
    Map<String, dynamic> responseJson = jsonDecode(response.body);


    int playoffW = 0;
    int playoffL = 0;
    int playoffT = 0;

    if (responseJson['playoff'] != null) {
      playoffW = (responseJson['playoff']['record']['wins'] as num).toInt();
      playoffL = (responseJson['playoff']['record']['losses'] as num).toInt();
      playoffT = (responseJson['playoff']['record']['ties'] as num).toInt();
    }

    return {
      'rank': (responseJson['qual']['ranking']['rank'] as num).toInt(),
      'rankingScore':
          (responseJson['qual']['ranking']['sort_orders'][0] as num).toDouble(),
      'avgMatch':
          (responseJson['qual']['ranking']['sort_orders'][1] as num).toDouble(),
      'avgCharge':
          (responseJson['qual']['ranking']['sort_orders'][2] as num).toDouble(),
      'avgAuto':
          (responseJson['qual']['ranking']['sort_orders'][3] as num).toDouble(),
      'wins':
          (responseJson['qual']['ranking']['record']['wins'] as num).toInt() +
              playoffW,
      'losses':
          (responseJson['qual']['ranking']['record']['losses'] as num).toInt() +
              playoffL,
      'ties':
          (responseJson['qual']['ranking']['record']['ties'] as num).toInt() +
              playoffT,
    };
  }

  static Future<List<Match>?> getTeamMatchSchedule() async {
    _prefs ??= await SharedPreferences.getInstance();

    int team = _prefs?.getInt('teamNumber') ?? 4788;
    String event = _prefs?.getString('eventKey') ?? '2024ausc';   // 2025ausc is the event key for the 2025 Australian Southern Cross Regional

    var url = Uri.parse(
        'https://www.thebluealliance.com/api/v3/team/frc$team/event/$event/matches');
    var response = await http.get(url,
        headers: {'accept': 'application/json', 'X-TBA-Auth-Key': await _apiKey});

    if (response.body == 'null') {
      return null;
    }

    List<dynamic> responseList = jsonDecode(response.body);
    List<Map<String, dynamic>> responseJson = responseList.cast();
    responseJson.sort((a, b) {
      return (a['predicted_time'] as num)
          .compareTo((b['predicted_time'] as num));     // sorts matches by time
    });   // responseJson is now a json of matches which the team plays in time order 

    List<Match> matches = [];
    for (Map<String, dynamic> matchJson in responseJson) {    // for (key, value) in responseJson
      String compLevel = matchJson['comp_level'];     // qm (qualifying match), sf (semifinal), f (final)
      compLevel = compLevel.toUpperCase();
      if (compLevel == 'QM') {
        compLevel = 'Q';
      }

      String matchNum = matchJson['match_number'].toString();
      if (compLevel != 'Q') {
        matchNum += '-${matchJson['set_number']}';
      }

      String key = matchJson['key'];
      int statpred = 0;
      // ignore: unnecessary_null_comparison
      if (key != null) {
        // ignore: non_constant_identifier_names
        var sb_url = Uri.parse('https://api.statbotics.io/v3/match/$key');
        // ignore: non_constant_identifier_names
        var sb_response =
            await http.get(sb_url, headers: {'accept': 'application/json'});

        // ignore: non_constant_identifier_names
        Map<String, dynamic> sb_responseList = jsonDecode(sb_response.body);
        // sb_responseJson = sb_responseList.cast();

        statpred =
            ((sb_responseList['pred']['red_win_prob'] as num) * 100).toInt();     // gets the probability of the red alliance winning (%)
      }

      List<String> redTeamsStr =
          (matchJson['alliances']['red']['team_keys'] as List<dynamic>).cast();
      List<int> redTeams = redTeamsStr
          .map((teamStr) => int.parse(teamStr.substring(3)))
          .toList();
      List<String> blueTeamsStr =
          (matchJson['alliances']['blue']['team_keys'] as List<dynamic>).cast();
      List<int> blueTeams = blueTeamsStr
          .map((teamStr) => int.parse(teamStr.substring(3)))
          .toList();

      if (matchJson['actual_time'] != null) {
        Outcome outcome = Outcome.tie;    // TODO: work out why the outcome is set to a tie by default. what does the api show for a tie?
        if (matchJson['winning_alliance'] == 'red') {
          outcome = Outcome.redWin;
        } else if (matchJson['winning_alliance'] == 'blue') {
          outcome = Outcome.blueWin;
        }

        matches.add(FinishedMatch(
          matchNumber: '$compLevel$matchNum',
          redTeams: redTeams,
          blueTeams: blueTeams,
          outcome: outcome,
          redScore: (matchJson['alliances']['red']['score'] as num).toInt(),
          blueScore: (matchJson['alliances']['blue']['score'] as num).toInt(),
          redRP: (matchJson['score_breakdown']['red']['rp'] as num).toInt(),
          blueRP: (matchJson['score_breakdown']['blue']['rp'] as num).toInt(),
          weAreRed: redTeams.contains(team),
          actualTime: DateTime.fromMillisecondsSinceEpoch(
              (matchJson['predicted_time'] as num).toInt() * 1000),
        ));
      } else {
        matches.add(UpcomingMatch(
          matchNumber: '$compLevel$matchNum',
          redTeams: redTeams,
          blueTeams: blueTeams,
          estimatedStartTime: DateTime.fromMillisecondsSinceEpoch(
              (matchJson['predicted_time'] as num).toInt() * 1000),
          statboticsPred: statpred,
          weAreRed: redTeams.contains(team),
        ));
      }
    }
    return matches; // returns Future<List<Match>?>
  }

  static Future<List<Match>?> getEventMatchSchedule() async {
    _prefs ??= await SharedPreferences.getInstance();

    String event = _prefs?.getString('eventKey') ?? '';

    var url = Uri.parse(
        'https://www.thebluealliance.com/api/v3/event/$event/matches');
    var response = await http.get(url,
        headers: {'accept': 'application/json', 'X-TBA-Auth-Key': await _apiKey});

    if (response.body == 'null') {
      return null;
    }

    List<dynamic> responseLst = jsonDecode(response.body);
    List<Map<String, dynamic>> responseJson = responseLst.cast();

    List<Match> matches = [];
    for (int i = 0; i < responseJson.length; i++) {

      Map<String, dynamic> matchJson = responseJson[i];

      String compLevel = matchJson['comp_level'];
      compLevel = compLevel.toUpperCase();
      if (compLevel == 'QM') {
        compLevel = 'Q';
      }

      String matchNum = matchJson['match_number'].toString();
      if (compLevel != 'Q') {
        matchNum += '-${matchJson['set_number']}';    // adds set number to non qualifying matches
      }

      List<String> redTeamsStr =
          (matchJson['alliances']['red']['team_keys'] as List<dynamic>).cast();
      List<int> redTeams = redTeamsStr
          .map((teamStr) => int.parse(teamStr.substring(3)))    // removes the 'frc' from the team number
          .toList();
      List<String> blueTeamsStr =
          (matchJson['alliances']['blue']['team_keys'] as List<dynamic>).cast();
      List<int> blueTeams = blueTeamsStr
          .map((teamStr) => int.parse(teamStr.substring(3)))
          .toList();

      if (matchJson['actual_time'] != null) {   // if the match has already happened
        Outcome outcome = Outcome.tie;
        if (matchJson['winning_alliance'] == 'red') {
          outcome = Outcome.redWin;
        } else if (matchJson['winning_alliance'] == 'blue') {
          outcome = Outcome.blueWin;
        }

        matches.add(FinishedMatch(
          matchNumber: '$compLevel$matchNum',
          redTeams: redTeams,
          blueTeams: blueTeams,
          outcome: outcome,
          redScore: (matchJson['alliances']['red']['score'] as num).toInt(),
          blueScore: (matchJson['alliances']['blue']['score'] as num).toInt(),
          redRP: (matchJson['score_breakdown']['red']['rp'] as num).toInt(),
          blueRP: (matchJson['score_breakdown']['blue']['rp'] as num).toInt(),
          actualTime: DateTime.fromMillisecondsSinceEpoch(
              (matchJson['predicted_time'] as num).toInt() * 1000),
        ));
      } else {
        matches.add(UpcomingMatch(
          matchNumber: '$compLevel$matchNum',
          redTeams: redTeams,
          blueTeams: blueTeams,
          statboticsPred: 1,
          estimatedStartTime: DateTime.fromMillisecondsSinceEpoch(
              (matchJson['predicted_time'] as num).toInt() * 1000),
        ));
      }
    }

    return matches;
  }
}

Future<String> getTBAAuthKey() async{
  try {
    await dotenv.load(fileName: '.env'); // Load environment variables
  } catch (e) {
    throw Exception('Error loading .env file: $e'); // Print error if any
  }

  var authKey = dotenv.env['TBA_Auth_Key'];
  if (authKey == null) {
    var logger = Logger();
    logger.e('TBA Auth Key not found in .env file');
    throw Exception('TBA Auth Key not found');
  }
  return authKey;
}
