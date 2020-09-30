import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/player.dart';
import 'package:bideuchre/data/stat_item.dart';
import 'package:bideuchre/data/stat_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../util.dart';
import 'games_section.dart';
import 'overview_section.dart';
import 'player_profile.dart';
import 'team_profile.dart';

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
    data = DataStore.lastData;
    playerIds = teamId.split(' ').toSet();
    textTheme = Theme.of(context).textTheme;
    List<Widget> children = [
      SizedBox(height: 8), // balance out dividers
      OverviewSection(teamId),
      GamesSection(teamId),
      playersSection(),
      opponentsSection(),
      SizedBox(height: 64),
    ];
    return SingleChildScrollView(child: Column(children: children));
  }

  Widget opponentsSection() {
    Map<String, List<int>> playerRecordsAgainst = {};
    Map<String, List<int>> teamRecordsAgainst = {};
    for (Game game in data.allGames.where((g) => (g.isFinished && !g.isArchived && g.teamIds.contains(teamId)))) {
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
    for (String oPlayerId in oPlayerIds) {
      Player oPlayer = data.players[oPlayerId];
      if (oPlayer != null) {
        List<int> record = playerRecordsAgainst[oPlayerId];
        String recordString = '${record[0]}-${record[1]}';
        Color color = data.statsDb.getEntityColor(oPlayerId);
        playersScrollChildren.add(
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PlayerProfile(oPlayer)));
              },
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 50,
                ),
                margin: EdgeInsets.all(8),
                child: Column(
                  children: <Widget>[
                    Text(oPlayer.shortName, style: textTheme.bodyText1.copyWith(color: color)),
                    Text(recordString, style: textTheme.bodyText2),
                  ],
                ),
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
        Color color = data.statsDb.getEntityColor(oTeamId);
        teamsScrollChildren.add(
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TeamProfile(oTeamId)));
              },
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 50,
                ),
                margin: EdgeInsets.all(8),
                child: Column(
                  children: <Widget>[
                    Text(teamName, style: textTheme.bodyText1.copyWith(color: color)),
                    Text(recordString, style: textTheme.bodyText2),
                  ],
                ),
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
          children: teamsScrollChildren,
        ),
      ),
    ));
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
        Color color = data.statsDb.getEntityColor(playerId);
        horizontalScrollChildren.add(
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 50,
                ),
                margin: EdgeInsets.all(8),
                child: Column(
                  children: <Widget>[
                    Text(player.fullName, style: textTheme.bodyText1.copyWith(color: color)),
                    Text(record.toString(), style: textTheme.bodyText2),
                  ],
                ),
              ),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PlayerProfile(player)));
              },
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
    children.add(Divider());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
