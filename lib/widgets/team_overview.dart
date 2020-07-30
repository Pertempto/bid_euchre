import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/player.dart';
import 'package:bideuchre/data/stats.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../util.dart';
import 'bidding_splits_section.dart';
import 'compare.dart';
import 'game_detail.dart';
import 'player_profile.dart';

class TeamOverview extends StatefulWidget {
  final String teamId;

  TeamOverview(this.teamId);

  @override
  _TeamOverviewState createState() => _TeamOverviewState();
}

class _TeamOverviewState extends State<TeamOverview> with AutomaticKeepAliveClientMixin<TeamOverview> {
  String teamId;
  Data data;
  TextTheme textTheme;
  Set<String> playerIds;
  bool opponentsSortByRecord = true;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    teamId = widget.teamId;
    print('teamId: $teamId');
    data = DataStore.lastData;
    playerIds = teamId.split(' ').toSet();
    print('building: ${DateTime.now().millisecondsSinceEpoch}');
    textTheme = Theme.of(context).textTheme;
    List<Widget> children = [
      SizedBox(height: 8), // balance out dividers
      overviewSection(),
      biddingSection(),
      BiddingSplitsSection(teamId),
      gamesSection(),
      playersSection(),
      opponentsSection(),
      SizedBox(height: 64),
    ];
    print('built: ${DateTime.now().millisecondsSinceEpoch}');
    return SingleChildScrollView(child: Column(children: children));
  }

  Widget biddingSection() {
    TextStyle titleStyle = textTheme.bodyText2.copyWith(fontWeight: FontWeight.w500);
    TextStyle statStyle = textTheme.bodyText2;
    List<Widget> children = [
      ListTile(
        title: Text('Bidding', style: textTheme.headline6),
        dense: true,
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text('Made-Set', style: titleStyle), flex: 5),
            Expanded(
              child: Text(data.statsDb.getStat(teamId, StatType.biddingRecord).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 3,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Bidding Rate', style: titleStyle), flex: 5),
            Expanded(
              child: Text(data.statsDb.getStat(teamId, StatType.biddingFrequency).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 3,
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text('Average Bid', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(teamId, StatType.averageBid).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Points Per Bid', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(teamId, StatType.pointsPerBid).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
          ],
        ),
      ),
    ];
    children.add(Divider());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget gamesSection() {
    print('games start: ${DateTime.now().millisecondsSinceEpoch}');

    List<Game> games = data.allGames.where((g) => g.teamIds.contains(teamId)).toList();

    Map<String, String> gameStatuses = {};
    Map<String, bool> flipScores = {};
    for (Game game in games) {
      List<String> teamsIds = game.teamIds;
      flipScores[game.gameId] = teamsIds[1] == teamId;
      if (!game.isFinished) {
        gameStatuses[game.gameId] = 'In Progress';
      } else {
        if (teamsIds[game.winningTeamIndex] == teamId) {
          gameStatuses[game.gameId] = 'Won';
        } else {
          gameStatuses[game.gameId] = 'Lost';
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
          if (game.userId == data.currentUser.userId ||
              data.relationshipsDb.canShare(game.userId, data.currentUser.userId)) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => GameDetail(game)));
          } else {
            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text('You don\'t have permission to view this game!'),
            ));
          }
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
    print('games end: ${DateTime.now().millisecondsSinceEpoch}');
    children.add(Divider());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget opponentsSection() {
    Map<String, List<int>> playerRecordsAgainst = {};
    Map<String, List<int>> teamRecordsAgainst = {};
    for (Game game in data.allGames.where((g) => (g.isFinished && g.teamIds.contains(teamId)))) {
      int winningTeam = game.winningTeamIndex;
      List<Set<String>> teamsPlayerIds = game.allTeamsPlayerIds;
      for (int teamIndex = 0; teamIndex < 2; teamIndex++) {
        List<String> teamIds = game.teamIds;
        if (teamIds[teamIndex] == teamId) {
          Set<String> opponentPlayerIds = teamsPlayerIds[1 - teamIndex];
          for (String opponentId in opponentPlayerIds) {
            playerRecordsAgainst.putIfAbsent(opponentId, () => [0, 0]);
            if (teamIndex == winningTeam) {
              playerRecordsAgainst[opponentId][0] += 1;
            } else {
              playerRecordsAgainst[opponentId][1] += 1;
            }
          }
          if (teamIds[1 - teamIndex] != null) {
            String oTeamId = teamIds[1 - teamIndex];
            teamRecordsAgainst.putIfAbsent(oTeamId, () => [0, 0]);
            if (teamIndex == winningTeam) {
              teamRecordsAgainst[oTeamId][0] += 1;
            } else {
              teamRecordsAgainst[oTeamId][1] += 1;
            }
          }
        }
      }
    }
    List<String> oPlayerIds = playerRecordsAgainst.keys.toList();
    oPlayerIds.sort((a, b) {
      if (opponentsSortByRecord) {
        double aPct = playerRecordsAgainst[a][0] / (playerRecordsAgainst[a][0] + playerRecordsAgainst[a][1]);
        double bPct = playerRecordsAgainst[b][0] / (playerRecordsAgainst[b][0] + playerRecordsAgainst[b][1]);
        int pctCmp = -aPct.compareTo(bPct);
        if (pctCmp != 0) {
          return pctCmp;
        }
      } else {
        int aGames = playerRecordsAgainst[a][0] + playerRecordsAgainst[a][1];
        int bGames = playerRecordsAgainst[b][0] + playerRecordsAgainst[b][1];
        int gamesCmp = -aGames.compareTo(bGames);
        if (gamesCmp != 0) {
          return gamesCmp;
        }
      }
      return -playerRecordsAgainst[a][0].compareTo(playerRecordsAgainst[b][0]);
    });
    List<String> oTeamIds = teamRecordsAgainst.keys.toList();
    oTeamIds.sort((a, b) {
      if (opponentsSortByRecord) {
        double aPct = teamRecordsAgainst[a][0] / (teamRecordsAgainst[a][0] + teamRecordsAgainst[a][1]);
        double bPct = teamRecordsAgainst[b][0] / (teamRecordsAgainst[b][0] + teamRecordsAgainst[b][1]);
        int pctCmp = -aPct.compareTo(bPct);
        if (pctCmp != 0) {
          return pctCmp;
        }
      } else {
        int aGames = teamRecordsAgainst[a][0] + teamRecordsAgainst[a][1];
        int bGames = teamRecordsAgainst[b][0] + teamRecordsAgainst[b][1];
        int gamesCmp = -aGames.compareTo(bGames);
        if (gamesCmp != 0) {
          return gamesCmp;
        }
      }
      return -teamRecordsAgainst[a][0].compareTo(teamRecordsAgainst[b][0]);
    });

    if (oPlayerIds.isEmpty && oTeamIds.isEmpty) {
      return Container();
    }
    List<Widget> children = [
      ListTile(
        title: Text('Opponents', style: textTheme.headline6),
        dense: true,
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(
          children: <Widget>[
            Text('Sort: ', style: textTheme.subtitle1),
            SizedBox(width: 32),
            Expanded(
              child: CupertinoSlidingSegmentedControl(
                groupValue: opponentsSortByRecord,
                onValueChanged: (value) {
                  setState(() {
                    opponentsSortByRecord = value;
                  });
                },
                children: {
                  true: Text('Record'),
                  false: Text('Games'),
                },
              ),
            ),
          ],
        ),
      ),
    ];
    List<Widget> playersScrollChildren = [SizedBox(width: 2)];
    for (String playerId in oPlayerIds) {
      Player player = data.players[playerId];
      if (player != null) {
        List<int> record = playerRecordsAgainst[playerId];
        String recordString = '${record[0]}-${record[1]}';
        playersScrollChildren.add(
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
          children: playersScrollChildren,
        ),
      ),
    ));
    List<Widget> teamsScrollChildren = [SizedBox(width: 2)];
    for (String oTeamId in oTeamIds) {
      String teamName = Util.teamName(oTeamId, data);
      if (teamName != null) {
        List<int> record = teamRecordsAgainst[oTeamId];
        String recordString = '${record[0]}-${record[1]}';
        teamsScrollChildren.add(
          GestureDetector(
            child: Card(
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 50,
                ),
                margin: EdgeInsets.all(8),
                child: Column(
                  children: <Widget>[
                    Text(teamName, style: textTheme.bodyText1),
                    Text(recordString, style: textTheme.bodyText2),
                  ],
                ),
              ),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Compare(teamId, oTeamId)));
            },
          ),
        );
      }
    }
    children.add(SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: Row(
          children: teamsScrollChildren,
        ),
      ),
    ));
    children.add(Divider());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
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
            Expanded(child: Text('Record', style: titleStyle), flex: 5),
            Expanded(
              child: Text(data.statsDb.getStat(teamId, StatType.record).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 3,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Streak', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(teamId, StatType.streak).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text('Games', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(teamId, StatType.numGames).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Rounds', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(teamId, StatType.numRounds).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text('Bids', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(teamId, StatType.numBids).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Points', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(teamId, StatType.numPoints).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
          ],
        ),
      ),
    ];
    children.add(Divider());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget playersSection() {
    List<String> playerIds = teamId.split(' ');
    playerIds.sort((a, b) => data.allPlayers[a].fullName.compareTo(data.allPlayers[b].fullName));
    List<Widget> children = [
      ListTile(
        title: Text('Players', style: textTheme.headline6),
        dense: true,
      ),
    ];
    List<Widget> horizontalScrollChildren = [SizedBox(width: 2)];
    for (String playerId in playerIds) {
      Player player = data.players[playerId];
      if (player != null) {
        StatItem record = data.statsDb.getStat(playerId, StatType.record);
        horizontalScrollChildren.add(
          GestureDetector(
            child: Card(
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 50,
                ),
                margin: EdgeInsets.all(8),
                child: Column(
                  children: <Widget>[
                    Text(player.fullName, style: textTheme.bodyText1),
                    Text(record.toString(), style: textTheme.bodyText2),
                  ],
                ),
              ),
            ),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => PlayerProfile(player)),
              );
            },
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
    children.add(Divider());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
