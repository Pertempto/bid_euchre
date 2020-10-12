import 'dart:math';

import 'package:bideuchre/data/stat_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../data/data_store.dart';
import '../data/game.dart';
import '../util.dart';
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
    data = DataStore.lastData;
    textTheme = Theme.of(context).textTheme;
    List<Widget> children = [
      gameHeader(game, data, textTheme, context),
      winningChancesSection(),
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
      children.addAll(teamBidsSection());
      children.addAll(teamPPBSection());
      children.addAll(teamBidderRatingsSection());
      children.addAll(playerBiddingDiffsSection());
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(children: children),
    );
  }

  List<Widget> teamBidsSection() {
    Map rawStatsMap = game.rawStatsMap;
    List<BiddingRecordStatItem> teamBidding =
        game.teamIds.map((teamId) => BiddingRecordStatItem.fromGamesStats([rawStatsMap[teamId]], true)).toList();
    List<Widget> children = [];
    // TODO: create function to reduce duplicate code between stat sections
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
    children.add(Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text('${teamBidding[0].record.wins}/${teamBidding[0].record.total}', style: textTheme.subtitle2),
          Spacer(),
          Text('Made Bids', style: textTheme.subtitle2),
          Spacer(),
          Text('${teamBidding[1].record.wins}/${teamBidding[1].record.total}', style: textTheme.subtitle2),
        ],
      ),
    ));
    List<Widget> bars = [];
    for (int i = 0; i < 2; i++) {
      bars.add(LinearPercentIndicator(
        percent: teamBidding[i].record.winningPercentage,
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
    return children;
  }

  List<Widget> teamPPBSection() {
    Map rawStatsMap = game.rawStatsMap;
    List<PointsPerBidStatItem> teamPPB =
    game.teamIds.map((teamId) => PointsPerBidStatItem.fromGamesStats([rawStatsMap[teamId]], true)).toList();
    List<Widget> children = [];
    children.add(Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text('${teamPPB[0]}', style: textTheme.subtitle2),
          Spacer(),
          Text('Points per Bid', style: textTheme.subtitle2),
          Spacer(),
          Text('${teamPPB[1]}', style: textTheme.subtitle2),
        ],
      ),
    ));
    List<Widget> bars = [];
    for (int i = 0; i < 2; i++) {
      double percent = 0;
      if (teamPPB[i].count != 0) {
        percent = max(0, min(1, teamPPB[i].average / 6));
      }
      bars.add(LinearPercentIndicator(
        percent: percent,
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
    return children;
  }

  List<Widget> teamBidderRatingsSection() {
    Map rawStatsMap = game.rawStatsMap;
    List<BidderRatingStatItem> teamBidderRatings =
    game.teamIds.map((teamId) => BidderRatingStatItem.fromGamesStats([rawStatsMap[teamId]], true)).toList();
    List<Widget> children = [];
    children.add(Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text('${teamBidderRatings[0]}', style: textTheme.subtitle2),
          Spacer(),
          Text('Bidder Rating', style: textTheme.subtitle2),
          Spacer(),
          Text('${teamBidderRatings[1]}', style: textTheme.subtitle2),
        ],
      ),
    ));
    List<Widget> bars = [];
    for (int i = 0; i < 2; i++) {
      double percent = max(0, min(1, teamBidderRatings[i].rating / 100));
      bars.add(LinearPercentIndicator(
        percent: percent,
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
    return children;
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
      playerBiddingDiffs[playerId] = PointsDiffPerBidStatItem
          .fromGamesStats([rawStatsMap[playerId]], false)
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

  Widget winningChancesSection() {
    List<double> winProbs =
        data.statsDb.calculateWinChances(game.initialPlayerIds, [0, 0], game.gameOverScore, beforeGameId: game.gameId);
    if (!game.isFinished) {
      winProbs = data.statsDb.calculateWinChances(game.initialPlayerIds, [0, 0], game.gameOverScore);
    }
    List<Widget> children = [
      Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text('Pre-Game Winning Chances', style: textTheme.subtitle2),
      ),
      Util.winProbsBar(winProbs, game.teamColors, context),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(children: children),
    );
  }
}
