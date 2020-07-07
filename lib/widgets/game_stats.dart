import 'dart:math';

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
    data = DataStore.lastData;
    textTheme = Theme.of(context).textTheme;
    List<Widget> children = [
      gameHeader(game, data, textTheme, context),
      statsSection(),
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
    for (Round round in game.rounds) {
      if (!round.isPlayerSwitch && round.isFinished) {
        int biddingTeam = round.bidderIndex % 2;
        teamNumBids[biddingTeam] += 1;
        if (round.madeBid) {
          teamMadeBids[biddingTeam] += 1;
        }
        teamTotalBids[biddingTeam] += round.bid;
        teamTotalBidPoints[biddingTeam] += round.score[biddingTeam];
      }
    }
    int totalBids = teamNumBids[0] + teamNumBids[1];
    List<Widget> children = [];

    if (totalBids == 0) {
      children.add(Text('No Stats'));
    } else {
      children.add(Padding(
        padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
        child: Column(
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
            LinearPercentIndicator(
              percent: teamNumBids[0] / totalBids,
              progressColor: game.teamColors[0],
              backgroundColor: game.teamColors[1],
              lineHeight: 12,
              linearStrokeCap: LinearStrokeCap.butt,
              padding: EdgeInsets.all(0),
            ),
          ],
        ),
      ));
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
      for (int i = 0; i < 2; i++) {
        double madePercent = 0;
        if (teamNumBids[i] != 0) {
          madePercent = teamMadeBids[i] / teamNumBids[i];
        }
        children.add(Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
          child: LinearPercentIndicator(
            percent: madePercent,
            progressColor: game.teamColors[i],
            lineHeight: 12,
            linearStrokeCap: LinearStrokeCap.butt,
            padding: EdgeInsets.all(0),
          ),
        ));
      }
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
      for (int i = 0; i < 2; i++) {
        double averageBid = 0;
        if (teamNumBids[i] != 0) {
          averageBid = teamTotalBids[i] / teamNumBids[i];
        }
        double percent = averageBid / 12;
        if (percent > 1) {
          percent = 1;
        }
        children.add(Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
          child: LinearPercentIndicator(
            percent: percent,
            progressColor: game.teamColors[i],
            lineHeight: 12,
            linearStrokeCap: LinearStrokeCap.butt,
            padding: EdgeInsets.all(0),
          ),
        ));
      }
      // Points Per Bid
      List<String> pointsPerBidStrings = [];
      for (int i = 0; i < 2; i++) {
        double pointsPerBid = 0;
        if (teamNumBids[i] != 0) {
          pointsPerBid = teamTotalBidPoints[i] / teamNumBids[i];
        }
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
      for (int i = 0; i < 2; i++) {
        double pointsPerBid = 0;
        if (teamNumBids[i] != 0) {
          pointsPerBid = teamTotalBidPoints[i] / teamNumBids[i];
        }
        double percent = max(0, min(1, pointsPerBid / 12));
        children.add(Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
          child: LinearPercentIndicator(
            percent: percent,
            progressColor: game.teamColors[i],
            lineHeight: 12,
            linearStrokeCap: LinearStrokeCap.butt,
            padding: EdgeInsets.all(0),
          ),
        ));
      }
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(children: children),
    );
  }
}
