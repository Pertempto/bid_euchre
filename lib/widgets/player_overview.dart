import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../util.dart';
import 'bidding_section.dart';
import 'bidding_splits_section.dart';
import 'compare.dart';
import 'games_section.dart';
import 'overview_section.dart';
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
    int start = DateTime.now().millisecondsSinceEpoch;
    player = widget.player;
    data = DataStore.lastData;
    textTheme = Theme.of(context).textTheme;
    List<Widget> children = [
      SizedBox(height: 8), // balance out dividers
      OverviewSection(player.playerId),
      BiddingSection(player.playerId),
      BiddingSplitsSection(player.playerId),
      GamesSection(player.playerId),
      partnersSection(),
      opponentsSection(),
      SizedBox(height: 64),
    ];
    int end = DateTime.now().millisecondsSinceEpoch;
    print('player overview build time: ${end - start}');
    return SingleChildScrollView(child: Column(children: children));
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
      if (opponentsSortByRecord) {
        double aPct = oppRecordsAgainst[a][0] / (oppRecordsAgainst[a][0] + oppRecordsAgainst[a][1]);
        double bPct = oppRecordsAgainst[b][0] / (oppRecordsAgainst[b][0] + oppRecordsAgainst[b][1]);
        int pctCmp = -aPct.compareTo(bPct);
        if (pctCmp != 0) {
          return pctCmp;
        }
      } else {
        int aGames = oppRecordsAgainst[a][0] + oppRecordsAgainst[a][1];
        int bGames = oppRecordsAgainst[b][0] + oppRecordsAgainst[b][1];
        int gamesCmp = -aGames.compareTo(bGames);
        if (gamesCmp != 0) {
          return gamesCmp;
        }
      }
      return -oppRecordsAgainst[a][0].compareTo(oppRecordsAgainst[b][0]);
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
        List<int> record = oppRecordsAgainst[oPlayerId];
        String recordString = '${record[0]}-${record[1]}';
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
                    Text(oPlayer.shortName, style: textTheme.bodyText1),
                    Text(recordString, style: textTheme.bodyText2),
                  ],
                ),
              ),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Compare(player.playerId, oPlayerId)));
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
      if (partnersSortByRecord) {
        double aPct = partnerRecords[a][0] / (partnerRecords[a][0] + partnerRecords[a][1]);
        double bPct = partnerRecords[b][0] / (partnerRecords[b][0] + partnerRecords[b][1]);
        int pctCmp = -aPct.compareTo(bPct);
        if (pctCmp != 0) {
          return pctCmp;
        }
      } else {
        int aGames = partnerRecords[a][0] + partnerRecords[a][1];
        int bGames = partnerRecords[b][0] + partnerRecords[b][1];
        int gamesCmp = -aGames.compareTo(bGames);
        if (gamesCmp != 0) {
          return gamesCmp;
        }
      }
      return -partnerRecords[a][0].compareTo(partnerRecords[b][0]);
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
        List<int> record = partnerRecords[partnerId];
        String recordString = '${record[0]}-${record[1]}';
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
                    Text(partner.shortName, style: textTheme.bodyText1),
                    Text(recordString, style: textTheme.bodyText2),
                  ],
                ),
              ),
            ),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => TeamProfile(Util.teamId([player.playerId, partnerId]))),
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
