import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/player.dart';
import 'package:bideuchre/data/record.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../util.dart';
import 'games_section.dart';
import 'overview_section.dart';
import 'player_profile.dart';
import 'team_profile.dart';

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
  bool partnersSortByRecord = true;
  bool opponentsSortByRecord = true;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    player = widget.player;
    data = DataStore.currentData;
    textTheme = Theme.of(context).textTheme;
    List<Widget> children = [
      SizedBox(height: 8), // balance out dividers
      OverviewSection(player.playerId),
      GamesSection(player.playerId),
      partnersSection(),
      opponentsSection(),
      SizedBox(height: 64),
    ];
    return SingleChildScrollView(child: Column(children: children));
  }

  Widget opponentsSection() {
    Map<String, Record> oppRecordsAgainst = {};
    for (Game game in data.allGames.where((g) => (g.isFinished &&
        (DataStore.displayArchivedStats || !g.isArchived) &&
        g.allPlayerIds.contains(player.playerId)))) {
      int winningTeam = game.winningTeamIndex;
      List<Set<String>> teamsPlayerIds = game.allTeamsPlayerIds;
      for (int teamIndex = 0; teamIndex < 2; teamIndex++) {
        Set<String> teamPlayerIds = teamsPlayerIds[teamIndex];
        if (teamPlayerIds.contains(player.playerId)) {
          Set<String> opponentPlayerIds = teamsPlayerIds[1 - teamIndex];
          for (String opponentId in opponentPlayerIds) {
            oppRecordsAgainst.putIfAbsent(opponentId, () => Record(0, 0));
            if (teamIndex == winningTeam) {
              oppRecordsAgainst[opponentId].addWin();
            } else {
              oppRecordsAgainst[opponentId].addLoss();
            }
          }
        }
      }
    }
    List<String> opponentIds = oppRecordsAgainst.keys.toList();
    opponentIds.sort((a, b) {
      if (opponentsSortByRecord) {
        double aPct = oppRecordsAgainst[a].winningPercentage;
        double bPct = oppRecordsAgainst[b].winningPercentage;
        int pctCmp = -aPct.compareTo(bPct);
        if (pctCmp != 0) {
          return pctCmp;
        }
      } else {
        int aGames = oppRecordsAgainst[a].total;
        int bGames = oppRecordsAgainst[b].total;
        int gamesCmp = -aGames.compareTo(bGames);
        if (gamesCmp != 0) {
          return gamesCmp;
        }
      }
      return -oppRecordsAgainst[a].wins.compareTo(oppRecordsAgainst[b].wins);
    });
    if (opponentIds.isEmpty) {
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
    List<Widget> horizontalScrollChildren = [SizedBox(width: 2)];
    for (String oPlayerId in opponentIds) {
      Player oPlayer = data.players[oPlayerId];
      if (oPlayer != null) {
        Record record = oppRecordsAgainst[oPlayerId];
        Color color = data.statsDb.getColor(oPlayerId);
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
                    Text(oPlayer.shortName, style: textTheme.bodyText1.copyWith(color: color)),
                    Text(opponentsSortByRecord ? record.toString() : record.total.toString(),
                        style: textTheme.bodyText2),
                  ],
                ),
              ),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PlayerProfile(oPlayer)));
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

  Widget partnersSection() {
    Map<String, Record> partnerRecords = {};
    for (Game game in data.allGames.where((g) =>
    (g.isFinished &&
        (DataStore.displayArchivedStats || !g.isArchived) &&
        g.allPlayerIds.contains(player.playerId)))) {
      int winningTeam = game.winningTeamIndex;
      List<Set<String>> teamsPlayerIds = game.allTeamsPlayerIds;
      for (int teamIndex = 0; teamIndex < 2; teamIndex++) {
        Set<String> teamPlayerIds = teamsPlayerIds[teamIndex];
        if (teamPlayerIds.contains(player.playerId) && teamPlayerIds.length == 2) {
          String partnerId = teamPlayerIds.firstWhere((id) => id != player.playerId);
          partnerRecords.putIfAbsent(partnerId, () => Record(0, 0));
          if (teamIndex == winningTeam) {
            partnerRecords[partnerId].addWin();
          } else {
            partnerRecords[partnerId].addLoss();
          }
        }
      }
    }
    List<String> partnerIds = partnerRecords.keys.toList();
    partnerIds.sort((a, b) {
      if (partnersSortByRecord) {
        double aPct = partnerRecords[a].winningPercentage;
        double bPct = partnerRecords[b].winningPercentage;
        int pctCmp = -aPct.compareTo(bPct);
        if (pctCmp != 0) {
          return pctCmp;
        }
      } else {
        int aGames = partnerRecords[a].total;
        int bGames = partnerRecords[b].total;
        int gamesCmp = -aGames.compareTo(bGames);
        if (gamesCmp != 0) {
          return gamesCmp;
        }
      }
      return -partnerRecords[a].wins.compareTo(partnerRecords[b].wins);
    });
    if (partnerIds.isEmpty) {
      return Container();
    }
    List<Widget> children = [
      ListTile(
        title: Text('Partners', style: textTheme.headline6),
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
                groupValue: partnersSortByRecord,
                onValueChanged: (value) {
                  setState(() {
                    partnersSortByRecord = value;
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
    List<Widget> horizontalScrollChildren = [SizedBox(width: 2)];
    for (String partnerId in partnerIds) {
      Player partner = data.players[partnerId];
      if (partner != null) {
        Record record = partnerRecords[partnerId];
        Color color = data.statsDb.getColor(Util.teamId([player.playerId, partnerId]));
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
                    Text(partner.shortName, style: textTheme.bodyText1.copyWith(color: color)),
                    Text(partnersSortByRecord ? record.toString() : record.total.toString(),
                        style: textTheme.bodyText2),
                  ],
                ),
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => TeamProfile(Util.teamId([player.playerId, partnerId]))),
                );
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
