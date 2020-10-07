import 'dart:math';

import 'package:bideuchre/data/round.dart';
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
    List<int> teamNumBids = [0, 0];
    List<int> teamMadeBids = [0, 0];
    List<int> teamTotalBids = [0, 0];
    List<int> teamTotalBidPoints = [0, 0];
    //TODO: use stats from game.rawStatsMap
    List<Map> teamsStats = [];
    Map<String, Map> playerStats = {};
    List<Set<String>> teamsPlayerIds = game.allTeamsPlayerIds;
    for (int i = 0; i < 2; i++) {
      teamsStats.add({
        'numBids': 0,
        'pointsDiffOnBids': 0,
        'teamIndex': i,
      });
      for (String playerId in teamsPlayerIds[i]) {
        playerStats[playerId] = {
          'numBids': 0,
          'pointsDiffOnBids': 0,
          'teamIndex': i,
        };
      }
    }
    int numRounds = 0;
    for (Round round in game.rounds) {
      if (!round.isPlayerSwitch && round.isFinished) {
        numRounds++;
        int biddingTeam = round.bidderIndex % 2;
        teamNumBids[biddingTeam] += 1;
        if (round.madeBid) {
          teamMadeBids[biddingTeam] += 1;
        }
        teamTotalBids[biddingTeam] += round.bid;
        teamTotalBidPoints[biddingTeam] += round.score[biddingTeam];
        String bidderId = game.getPlayerIdsAfterRound(round.roundIndex - 1)[round.bidderIndex];
        teamsStats[biddingTeam]['numBids']++;
        teamsStats[biddingTeam]['pointsDiffOnBids'] += round.score[biddingTeam] - round.score[1 - biddingTeam];
        playerStats[bidderId]['numBids']++;
        playerStats[bidderId]['pointsDiffOnBids'] += round.score[biddingTeam] - round.score[1 - biddingTeam];
      }
    }
    for (int i = 0; i < 2; i++) {
      teamsStats[i]['numRounds'] = numRounds;
    }
    for (String playerId in playerStats.keys) {
      playerStats[playerId]['numRounds'] = numRounds;
    }
    List<Widget> children = [];

    List<Widget> bars = [];
    if (numRounds != 0) {
      children.add(Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text('${teamNumBids[0]}', style: textTheme.subtitle2),
              Spacer(),
              Text('Bids', style: textTheme.subtitle2),
              Spacer(),
              Text('${teamNumBids[1]}', style: textTheme.subtitle2),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: LinearPercentIndicator(
              percent: teamNumBids[0] / numRounds,
              progressColor: game.teamColors[0],
              backgroundColor: game.teamColors[1],
              lineHeight: 12,
              linearStrokeCap: LinearStrokeCap.butt,
              padding: EdgeInsets.all(0),
            ),
          ),
        ],
      ));
    }
    // Made Bids
    children.add(Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text('${teamMadeBids[0]}/${teamNumBids[0]}', style: textTheme.subtitle2),
          Spacer(),
          Text('Made Bids', style: textTheme.subtitle2),
          Spacer(),
          Text('${teamMadeBids[1]}/${teamNumBids[1]}', style: textTheme.subtitle2),
        ],
      ),
    ));
    bars = [];
    for (int i = 0; i < 2; i++) {
      double madePercent = 0;
      if (teamNumBids[i] != 0) {
        madePercent = teamMadeBids[i] / teamNumBids[i];
      }
      bars.add(LinearPercentIndicator(
        percent: madePercent,
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
    // Average Bid
    List<String> averageBidStrings = [];
    for (int i = 0; i < 2; i++) {
      double averageBid = 0;
      if (teamNumBids[i] != 0) {
        averageBid = teamTotalBids[i] / teamNumBids[i];
      }
      averageBidStrings.add(averageBid.toStringAsFixed(2));
    }
    children.add(Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text('${averageBidStrings[0]}', style: textTheme.subtitle2),
          Spacer(),
          Text('Average Bid', style: textTheme.subtitle2),
          Spacer(),
          Text('${averageBidStrings[1]}', style: textTheme.subtitle2),
        ],
      ),
    ));
    bars = [];
    for (int i = 0; i < 2; i++) {
      double averageBid = 0;
      if (teamNumBids[i] != 0) {
        averageBid = teamTotalBids[i] / teamNumBids[i];
      }
      double percent = averageBid / 12;
      if (percent > 1) {
        percent = 1;
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
    // Points Per Bid
    List<double> ppbs = [];
    List<String> pointsPerBidStrings = [];
    for (int i = 0; i < 2; i++) {
      double pointsPerBid = 0;
      if (teamNumBids[i] != 0) {
        pointsPerBid = teamTotalBidPoints[i] / teamNumBids[i];
      }
      ppbs.add(pointsPerBid);
      pointsPerBidStrings.add(pointsPerBid.toStringAsFixed(2));
    }
    children.add(Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text('${pointsPerBidStrings[0]}', style: textTheme.subtitle2),
          Spacer(),
          Text('Points per Bid', style: textTheme.subtitle2),
          Spacer(),
          Text('${pointsPerBidStrings[1]}', style: textTheme.subtitle2),
        ],
      ),
    ));
    bars = [];
    for (int i = 0; i < 2; i++) {
      double percent = max(0, min(1, ppbs[i] / 6));
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

    List<double> teamBidderRatings = [];
    List<String> teamBidderRatingStrings = [];
    for (int i = 0; i < 2; i++) {
      double rating = BidderRatingStatItem.calculateBidderRating([teamsStats[i]], true);
      teamBidderRatings.add(rating);
      teamBidderRatingStrings.add(rating.toStringAsFixed(1));
    }
    children.add(Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text('${teamBidderRatingStrings[0]}', style: textTheme.subtitle2),
          Spacer(),
          Text('Bidder Rating', style: textTheme.subtitle2),
          Spacer(),
          Text('${teamBidderRatingStrings[1]}', style: textTheme.subtitle2),
        ],
      ),
    ));
    bars = [];
    for (int i = 0; i < 2; i++) {
      double percent = max(0, min(1, teamBidderRatings[i] / 100));
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
    children.add(Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text('Bidding Diffs', style: textTheme.subtitle2),
    ));
    List<String> playerIds = playerStats.keys.toList();
    Map<String, int> playerBiddingDiffs = {};
    Map rawGameStats = game.rawStatsMap;
    for (String playerId in playerIds) {
      playerBiddingDiffs[playerId] = PointsDiffPerBidStatItem.fromGamesStats([rawGameStats[playerId]], false).sum;
    }
    playerIds.sort((a, b) {
      return -playerBiddingDiffs[a].compareTo(playerBiddingDiffs[b]);
    });
    for (String playerId in playerIds) {
      int teamIndex = playerStats[playerId]['teamIndex'];
      double percent = max(0, min(1, playerBiddingDiffs[playerId] / numRounds));
      children.add(Padding(
        padding: EdgeInsets.only(top: 4),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(children: children),
    );
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
