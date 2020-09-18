import 'dart:math';

import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/stats.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TrendsSection extends StatefulWidget {
  final String id;

  TrendsSection(this.id);

  @override
  _TrendsSectionState createState() => _TrendsSectionState();
}

class _TrendsSectionState extends State<TrendsSection>
    with AutomaticKeepAliveClientMixin<TrendsSection>, SingleTickerProviderStateMixin {
  static const List<StatType> SELECTABLE_STATS = [StatType.overallRating, StatType.bidderRating];
  String id;
  Data data;
  StatType displayStat = StatType.overallRating;

  bool get wantKeepAlive => true;

  bool get isTeam => id.contains(' ');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    id = widget.id;
    data = DataStore.lastData;
    List<Game> games = data.statsDb.getGames(id);
    if (games.length < StatsDb.MIN_GAMES) {
      return Container();
    }
    int numGames = min(games.length, StatsDb.NUM_RECENT_GAMES);
    TextTheme textTheme = Theme.of(context).textTheme;
    List<Widget> children = [];
    Color color = data.statsDb.getColor(id);
    children.add(ListTile(
      title: Text('Recent Trends', style: textTheme.headline6),
      dense: true,
    ));
    children.add(Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: CupertinoSlidingSegmentedControl(
        groupValue: displayStat,
        children: Map.fromIterable(SELECTABLE_STATS, value: (n) => Text(StatsDb.statName(n))),
        onValueChanged: (value) {
          setState(() {
            displayStat = value;
          });
        },
      ),
    ));
    children.add(Container(
//        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: LineChart(
              LineChartData(
                lineBarsData: List.generate(1, (index) {
                  StatType stat = displayStat;
                  return LineChartBarData(
                    show: stat == displayStat,
                    spots: List.generate(numGames, (index) {
                      double rating = data.statsDb.getRatingAfterGame(id, games[index].gameId);
                      if (stat == StatType.overallRating) {
                        rating = data.statsDb.getRatingAfterGame(id, games[index].gameId);
                      } else if (stat == StatType.bidderRating) {
                        rating = data.statsDb.getBidderRatingAfterGame(id, games[index].gameId);
                      }
                      rating = (rating * 10).round() / 10.0;
                      return FlSpot((numGames - index).toDouble(), rating);
                    }),
                    colors: [color],
                    barWidth: 4,
                    isCurved: true,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(radius: 4, color: color, strokeColor: color),
                    ),
                  );
                }),
                lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.grey[300].withOpacity(0.95),
                      tooltipBottomMargin: 24,
                      tooltipPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      fitInsideHorizontally: true,
                    ),
                    touchSpotThreshold: 30,
                    getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((e) {
                        return TouchedSpotIndicatorData(
                            FlLine(color: Colors.grey, strokeWidth: 4, dashArray: [8]), FlDotData(show: true));
                      }).toList();
                    }),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                    bottomTitles: SideTitles(showTitles: false),
                    leftTitles: SideTitles(
                        showTitles: true,
                        margin: 8,
                        getTitles: (value) {
                          return value.toStringAsFixed(1);
                        },
                        checkToShowTitle: (minValue, maxValue, sideTitles, appliedInterval, value) {
                          return value == minValue || value == maxValue;
                        })),
              ),
            ),
          ),
        ],
      ),
    ));
    children.add(Divider());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
