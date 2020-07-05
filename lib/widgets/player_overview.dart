import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/player.dart';
import 'package:bideuchre/data/stats.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../util.dart';
import 'game_detail.dart';

class PlayerOverview extends StatefulWidget {
  final Player player;

  PlayerOverview(this.player);

  @override
  _PlayerOverviewState createState() => _PlayerOverviewState();
}

class _PlayerOverviewState extends State<PlayerOverview> with AutomaticKeepAliveClientMixin<PlayerOverview> {
  Player player;
  Data data;
  TextTheme textTheme;
  Map<StatType, StatItem> playerStats;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    player = widget.player;
    data = DataStore.lastData;
    playerStats = data.statsDb.getPlayerStats(
        {StatType.record, StatType.streak, StatType.numGames, StatType.numRounds, StatType.numBids, StatType.numPoints},
        {player.playerId})[player.playerId];
    print('building: ${DateTime.now().millisecondsSinceEpoch}');
    textTheme = Theme.of(context).textTheme;
    List<Widget> children = [
      SizedBox(height: 8), // balance out dividers
      overviewSection(),
      Divider(),
      gamesSection(),
      Divider(),
      partnersSection(),
      Divider(),
      opponentsSection(),
      Divider(),
      SizedBox(height: 64),
    ];
    print('built: ${DateTime.now().millisecondsSinceEpoch}');
    return SingleChildScrollView(child: Column(children: children));
  }

  Widget overviewSection() {
    TextStyle titleStyle = textTheme.bodyText2.copyWith(fontWeight: FontWeight.w500);
    TextStyle statStyle = textTheme.bodyText2;
    List<Widget> children = [
      ListTile(
        title: Text('Overview', style: textTheme.headline6),
        dense: true,
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text('Record', style: titleStyle), flex: 2),
            Expanded(
              child: Text(playerStats[StatType.record].toString(), style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Streak', style: titleStyle), flex: 2),
            Expanded(
              child: Text(playerStats[StatType.streak].toString(), style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text('Games', style: titleStyle), flex: 2),
            Expanded(
              child: Text(playerStats[StatType.numGames].toString(), style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Rounds', style: titleStyle), flex: 2),
            Expanded(
              child: Text(playerStats[StatType.numRounds].toString(), style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text('Bids', style: titleStyle), flex: 2),
            Expanded(
              child: Text(playerStats[StatType.numBids].toString(), style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Points', style: titleStyle), flex: 2),
            Expanded(
              child: Text(playerStats[StatType.numPoints].toString(), style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
          ],
        ),
      ),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget gamesSection() {
    List<Game> games = data.games.where((g) => (g.allPlayerIds.contains(player.playerId))).toList();
    Map<String, String> gameStatuses = {};
    Map<String, bool> flipScores = {};
    for (Game game in games) {
      List<Set<String>> teamsPlayerIds = game.allTeamsPlayerIds;
      flipScores[game.gameId] = !teamsPlayerIds[0].contains(player.playerId);
      if (!game.isFinished) {
        gameStatuses[game.gameId] = 'In Progress';
      } else {
        if (game.fullGamePlayerIds.contains(player.playerId)) {
          if (teamsPlayerIds[game.winningTeamIndex].contains(player.playerId)) {
            gameStatuses[game.gameId] = 'Won';
          } else {
            gameStatuses[game.gameId] = 'Lost';
          }
        } else {
          gameStatuses[game.gameId] = 'Partial';
        }
      }
    }

    List<Widget> children = [
      ListTile(
        title: Text('Games', style: textTheme.headline6),
        dense: true,
      ),
    ];
    List<Widget> horizontalScrollChildren = [SizedBox(width: 2)];
    for (Game game in games) {
      List<int> score = game.currentScore;
      List<Widget> scoreChildren = [
        Text(Util.scoreString(score[0]), style: textTheme.headline4.copyWith(color: game.teamColors[0])),
        Padding(padding: EdgeInsets.fromLTRB(1, 0, 1, 0), child: Text('-', style: textTheme.headline5)),
        Text(Util.scoreString(score[1]), style: textTheme.headline4.copyWith(color: game.teamColors[1])),
      ];
      if (flipScores[game.gameId]) {
        scoreChildren = scoreChildren.reversed.toList();
      }
      DateTime date = DateTime.fromMillisecondsSinceEpoch(game.timestamp);
      String dateString = intl.DateFormat.yMd().format(date);
      String timeString = intl.DateFormat.jm().format(date);
      horizontalScrollChildren.add(GestureDetector(
        child: Card(
          child: Container(
            constraints: BoxConstraints(
              minWidth: 100,
            ),
            margin: EdgeInsets.all(8),
            child: Column(
              children: <Widget>[
                Text(gameStatuses[game.gameId], style: textTheme.bodyText1),
                Row(children: scoreChildren),
                Text(dateString, style: textTheme.caption),
                Text(timeString, style: textTheme.caption),
              ],
            ),
          ),
        ),
        onTap: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => GameDetail(game)));
        },
      ));
    }
    children.add(SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: Row(
          children: horizontalScrollChildren,
        ),
      ),
    ));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget partnersSection() {
    Map<String, List<int>> partnerRecords = {};
    for (Game game in data.allGames.where((g) => (g.isFinished && g.allPlayerIds.contains(player.playerId)))) {
      int winningTeam = game.winningTeamIndex;
      List<Set<String>> teamsPlayerIds = game.allTeamsPlayerIds;
      for (int teamIndex = 0; teamIndex < 2; teamIndex++) {
        Set<String> teamPlayerIds = teamsPlayerIds[teamIndex];
        if (teamPlayerIds.contains(player.playerId) && teamPlayerIds.length == 2) {
          String partnerId = teamPlayerIds.firstWhere((id) => id != player.playerId);
          partnerRecords.putIfAbsent(partnerId, () => [0, 0]);
          if (teamIndex == winningTeam) {
            partnerRecords[partnerId][0] += 1;
          } else {
            partnerRecords[partnerId][1] += 1;
          }
        }
      }
    }
    List<String> partnerIds = partnerRecords.keys.toList();
    partnerIds.sort((a, b) {
      double aPct = partnerRecords[a][0] / (partnerRecords[a][0] + partnerRecords[a][1]);
      double bPct = partnerRecords[b][0] / (partnerRecords[b][0] + partnerRecords[b][1]);
      int pctCmp = -aPct.compareTo(bPct);
      if (pctCmp != 0) {
        return pctCmp;
      }
      return -partnerRecords[a][0].compareTo(partnerRecords[b][0]);
    });

    List<Widget> children = [
      ListTile(
        title: Text('Partners', style: textTheme.headline6),
        dense: true,
      ),
    ];
    List<Widget> horizontalScrollChildren = [SizedBox(width: 2)];
    for (String playerId in partnerIds) {
      Player player = data.players[playerId];
      if (player != null) {
        List<int> record = partnerRecords[playerId];
        String recordString = '${record[0]}-${record[1]}';
        horizontalScrollChildren.add(
          Card(
            child: Container(
              constraints: BoxConstraints(
                minWidth: 50,
              ),
              margin: EdgeInsets.all(8),
              child: Column(
                children: <Widget>[
                  Text(player.shortName, style: textTheme.bodyText1),
                  Text(recordString, style: textTheme.bodyText2),
                ],
              ),
            ),
          ),
        );
      }
    }
    children.add(SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: Row(
          children: horizontalScrollChildren,
        ),
      ),
    ));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget opponentsSection() {
    Map<String, List<int>> oppRecordsAgainst = {};
    for (Game game in data.allGames.where((g) => (g.isFinished && g.allPlayerIds.contains(player.playerId)))) {
      int winningTeam = game.winningTeamIndex;
      List<Set<String>> teamsPlayerIds = game.allTeamsPlayerIds;
      for (int teamIndex = 0; teamIndex < 2; teamIndex++) {
        Set<String> teamPlayerIds = teamsPlayerIds[teamIndex];
        if (teamPlayerIds.contains(player.playerId)) {
          Set<String> opponentPlayerIds = teamsPlayerIds[1 - teamIndex];
          for (String opponentId in opponentPlayerIds) {
            oppRecordsAgainst.putIfAbsent(opponentId, () => [0, 0]);
            if (teamIndex == winningTeam) {
              oppRecordsAgainst[opponentId][0] += 1;
            } else {
              oppRecordsAgainst[opponentId][1] += 1;
            }
          }
        }
      }
    }
    List<String> opponentIds = oppRecordsAgainst.keys.toList();
    opponentIds.sort((a, b) {
      double aPct = oppRecordsAgainst[a][0] / (oppRecordsAgainst[a][0] + oppRecordsAgainst[a][1]);
      double bPct = oppRecordsAgainst[b][0] / (oppRecordsAgainst[b][0] + oppRecordsAgainst[b][1]);
      int pctCmp = -aPct.compareTo(bPct);
      if (pctCmp != 0) {
        return pctCmp;
      }
      return -oppRecordsAgainst[a][0].compareTo(oppRecordsAgainst[b][0]);
    });

    List<Widget> children = [
      ListTile(
        title: Text('Opponents', style: textTheme.headline6),
        dense: true,
      ),
    ];
    List<Widget> horizontalScrollChildren = [SizedBox(width: 2)];
    for (String playerId in opponentIds) {
      Player player = data.players[playerId];
      if (player != null) {
        List<int> record = oppRecordsAgainst[playerId];
        String recordString = '${record[0]}-${record[1]}';
        horizontalScrollChildren.add(
          Card(
            child: Container(
              constraints: BoxConstraints(
                minWidth: 50,
              ),
              margin: EdgeInsets.all(8),
              child: Column(
                children: <Widget>[
                  Text(player.shortName, style: textTheme.bodyText1),
                  Text(recordString, style: textTheme.bodyText2),
                ],
              ),
            ),
          ),
        );
      }
    }
    children.add(SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: Row(
          children: horizontalScrollChildren,
        ),
      ),
    ));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
