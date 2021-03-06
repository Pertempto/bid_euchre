import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/stat_item.dart';
import 'package:bideuchre/data/stat_type.dart';
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
  static const List<StatType> SELECTABLE_STATS = [
    StatType.overallRating,
    StatType.bidderRating,
    StatType.winnerRating,
    StatType.setterRating
  ];
  String id;
  Data data;
  List<Game> games;
  StatType displayStat = StatType.overallRating;

  bool get isTeam => id.contains(' ');

  int get numGames => games.length;

  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    id = widget.id;
    data = DataStore.currentData;
    games = data.statsDb.getGames(id, DataStore.displayArchivedStats);
    if (games.length < 2) {
      return Container();
    }
    TextTheme textTheme = Theme.of(context).textTheme;
    List<Widget> children = [];
    children.add(ListTile(
      title: Text('Recent Trends', style: textTheme.headline6),
      dense: true,
    ));
    children.add(Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: CupertinoSlidingSegmentedControl(
        groupValue: displayStat,
        children: Map.fromIterable(SELECTABLE_STATS, value: (st) => Text(StatItem.getStatName(st).split(' ')[0])),
        onValueChanged: (value) {
          setState(() {
            displayStat = value;
          });
        },
      ),
    ));

    Widget lineChart = getLineChart();
    EdgeInsets padding = EdgeInsets.fromLTRB(24, 40, 24, 16);
    double height = 250;
    double width = numGames * 5.0;
    if (width < MediaQuery.of(context).size.width) {
      children.add(Container(
        height: height,
        width: double.infinity,
        padding: padding,
        child: lineChart,
      ));
    } else {
      children.add(SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          height: height,
          width: width,
          padding: padding,
          child: lineChart,
        ),
      ));
    }
    children.add(Divider());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget getLineChart() {
    Color color = data.statsDb.getColor(id);
    List<LineChartBarData> lineBarsData = List.generate(1, (index) {
      StatType stat = displayStat;
      return LineChartBarData(
        spots: List.generate(numGames, (index) {
          double rating;
          // TODO: combine different ___RatingAfterGame methods
          if (stat == StatType.overallRating) {
            rating = data.statsDb
                .getRatingAfterGame(id, games[index].gameId, includeArchived: DataStore.displayArchivedStats);
          } else if (stat == StatType.bidderRating) {
            rating = data.statsDb
                .getBidderRatingAfterGame(id, games[index].gameId, includeArchived: DataStore.displayArchivedStats);
          } else if (stat == StatType.winnerRating) {
            rating = data.statsDb
                .getWinnerRatingAfterGame(id, games[index].gameId, includeArchived: DataStore.displayArchivedStats);
          } else if (stat == StatType.setterRating) {
            rating = data.statsDb
                .getSetterRatingAfterGame(id, games[index].gameId, includeArchived: DataStore.displayArchivedStats);
          }
          rating = (rating * 10).round() / 10.0;
          return FlSpot((numGames - index).toDouble(), rating);
        }),
        colors: [color],
        barWidth: 4,
        isCurved: true,
        curveSmoothness: 0.3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: false,
        ),
      );
    }).toList();
    return LineChart(
      LineChartData(
        lineBarsData: lineBarsData,
        lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.grey[300].withOpacity(0.95),
              tooltipBottomMargin: 8,
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
    );
  }
}
