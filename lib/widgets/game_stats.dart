import 'dart:math';

import 'package:bideuchre/data/stat_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../data/data_store.dart';
import '../data/game.dart';
import 'game_overview.dart';

class GameStats extends StatefulWidget {
  final Game game;

  GameStats(this.game);

  @override
  _GameStatsState createState() => _GameStatsState();
}

class _GameStatsState extends State<GameStats> {
  Game game;
  Data data;
  TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    game = widget.game;
    data = DataStore.currentData;
    textTheme = Theme.of(context).textTheme;
    List<Widget> children = [
      gameHeader(game, data, textTheme, context),
      statsSection(),
      SizedBox(height: 64),
    ];
    return SingleChildScrollView(
      child: Column(children: children),
    );
  }

  Widget statsSection() {
    List<Widget> children = [];

    if (game.numRounds != 0) {
      children.add(teamBidsSection());
      children.add(teamPPBSection());
      children.add(teamBidderRatingsSection());
      children.addAll(playerBiddingDiffsSection());
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(children: children),
    );
  }

  Widget teamBidsSection() {
    Map rawStatsMap = game.rawStatsMap;
    List<BiddingRecordStatItem> teamBidding =
        game.teamIds.map((teamId) => BiddingRecordStatItem.fromRawStats([rawStatsMap[teamId]], true)).toList();
    List<Widget> children = [];
    children.add(Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text('${teamBidding[0].record.total}', style: textTheme.subtitle2),
            Spacer(),
            Text('Bids', style: textTheme.subtitle2),
            Spacer(),
            Text('${teamBidding[1].record.total}', style: textTheme.subtitle2),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: 2),
          child: LinearPercentIndicator(
            percent: teamBidding[0].record.total / game.numRounds,
            progressColor: game.teamColors[0],
            backgroundColor: game.teamColors[1],
            lineHeight: 12,
            linearStrokeCap: LinearStrokeCap.butt,
            padding: EdgeInsets.all(0),
          ),
        ),
      ],
    ));
    children.add(statBarsSection(
      'Made Bids',
      '${teamBidding[0].record.wins}/${teamBidding[0].record.total}',
      '${teamBidding[1].record.wins}/${teamBidding[1].record.total}',
      List.generate(2, (i) => teamBidding[i].record.winningPercentage),
    ));
    return Column(children: children);
  }

  Widget teamPPBSection() {
    Map rawStatsMap = game.rawStatsMap;
    List<GainedPerBidStatItem> teamGainedPerBids =
    game.teamIds.map((teamId) => GainedPerBidStatItem.fromRawStats([rawStatsMap[teamId]], true)).toList();
    return statBarsSection('Gained Per Bid', teamGainedPerBids[0].toString(), teamGainedPerBids[1].toString(),
        List.generate(2, (i) => max(0, min(1, teamGainedPerBids[i].average / 4))));
  }

  Widget teamBidderRatingsSection() {
    Map rawStatsMap = game.rawStatsMap;
    List<BidderRatingStatItem> teamBidderRatings =
    game.teamIds.map((teamId) => BidderRatingStatItem.fromRawStats([rawStatsMap[teamId]], true)).toList();
    return statBarsSection('Bidder Rating', teamBidderRatings[0].toString(), teamBidderRatings[1].toString(),
        List.generate(2, (i) => max(0, min(1, teamBidderRatings[i].rating / 100))));
  }

  List<Widget> playerBiddingDiffsSection() {
    List<Widget> children = [];
    children.add(Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text('Bidding Diffs', style: textTheme.subtitle2),
    ));
    Map<String, int> playerBiddingDiffs = {};
    List<String> playerIds = game.allPlayerIds.toList();
    Map rawStatsMap = game.rawStatsMap;
    for (String playerId in playerIds) {
      playerBiddingDiffs[playerId] = GainedPerBidStatItem
          .fromRawStats([rawStatsMap[playerId]], false)
          .sum;
    }
    playerIds.sort((a, b) {
      return -playerBiddingDiffs[a].compareTo(playerBiddingDiffs[b]);
    });
    List<Set<String>> allTeamsPlayersIds = game.allTeamsPlayerIds;
    for (String playerId in playerIds) {
      int teamIndex = 0;
      if (allTeamsPlayersIds[1].contains(playerId)) {
        teamIndex = 1;
      }
      int numRounds = game.numRounds;
      double percent = 0;
      if (numRounds != 0) {
        percent = max(0, min(1, playerBiddingDiffs[playerId] / numRounds));
      }
      children.add(Padding(
        padding: EdgeInsets.only(bottom: 4),
        child: Column(
          children: [
            Row(
              children: [
                Text(data.allPlayers[playerId].shortName,
                    style: textTheme.subtitle2.copyWith(color: game.teamColors[teamIndex])),
                Spacer(),
                Text(playerBiddingDiffs[playerId].toString(), style: textTheme.subtitle2),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: LinearPercentIndicator(
                percent: percent,
                progressColor: game.teamColors[teamIndex],
                lineHeight: 12,
                linearStrokeCap: LinearStrokeCap.butt,
                padding: EdgeInsets.all(0),
              ),
            ),
          ],
        ),
      ));
    }
    return children;
  }

  Widget statBarsSection(String title, String leftLabel, String rightLabel, List<double> barPercents) {
    List<Widget> children = [];
    children.add(Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(child: Text(leftLabel, style: textTheme.subtitle2, textAlign: TextAlign.start), flex: 1),
          Expanded(child: Text(title, style: textTheme.subtitle2, textAlign: TextAlign.center), flex: 2),
          Expanded(child: Text(rightLabel, style: textTheme.subtitle2, textAlign: TextAlign.end), flex: 1),
        ],
      ),
    ));
    List<Widget> bars = [];
    for (int i = 0; i < 2; i++) {
      if (barPercents[i].isNaN) {
        print(title);
      }
      bars.add(LinearPercentIndicator(
        percent: barPercents[i].isNaN ? 0 : barPercents[i],
        progressColor: game.teamColors[i],
        lineHeight: 12,
        linearStrokeCap: LinearStrokeCap.butt,
        padding: EdgeInsets.all(0),
      ));
    }
    children.add(Padding(
      padding: EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(child: bars[0]),
          SizedBox(width: 16),
          Expanded(child: bars[1]),
        ],
      ),
    ));
    return Column(children: children);
  }
}
