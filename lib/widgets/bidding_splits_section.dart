import 'package:bideuchre/data/bidding_split.dart';
import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/round.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BiddingSplitsSection extends StatefulWidget {
  final String id;
  final String id2;

  BiddingSplitsSection(this.id, {this.id2});

  @override
  _BiddingSplitsSectionState createState() => _BiddingSplitsSectionState();
}

class _BiddingSplitsSectionState extends State<BiddingSplitsSection>
    with AutomaticKeepAliveClientMixin<BiddingSplitsSection>, SingleTickerProviderStateMixin {
  static const Map<int, Color> BID_COLORS = {
    3: Colors.orange,
    4: Colors.green,
    5: Colors.purple,
    6: Colors.lime,
    12: Colors.lightBlue,
    24: Colors.deepPurple,
  };
  static const double PIE_THICKNESS = 30;
  static final NumberFormat decimalFormat = NumberFormat('###.#');

  String id1;
  String id2;
  Data data;
  int numRecentBids = 0;
  DisplayMode displayMode = DisplayMode.count;
  List<int> totalMade;
  List<int> totalBids;
  List<Map<int, BiddingSplit>> splits;

  bool get wantKeepAlive => true;

  bool get isCompare {
    return id2 != null;
  }

  List<String> get ids {
    return [id1, id2];
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    id1 = widget.id;
    id2 = widget.id2;
    data = DataStore.currentData;
    TextTheme textTheme = Theme.of(context).textTheme;
    getSplits();
    if (!isCompare && totalBids[0] == 0) {
      return Container();
    }
    List<Widget> children = [
      isCompare
          ? Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Bidding Splits', style: textTheme.headline6),
            )
          : ListTile(
              title: Text('Bidding Splits', style: textTheme.headline6),
              dense: true,
            ),
      Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: CupertinoSlidingSegmentedControl(
          groupValue: numRecentBids,
          children: Map.fromIterable([10, 20, 50, 0], value: (n) => Text(n == 0 ? 'All Time' : 'Last $n')),
          onValueChanged: (value) {
            setState(() {
              numRecentBids = value;
              getSplits();
            });
          },
        ),
      ),
      Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: CupertinoSlidingSegmentedControl(
          groupValue: displayMode,
          children: {
            DisplayMode.madePercentage: Text('Made %'),
            DisplayMode.made: Text('Made'),
            DisplayMode.count: Text('Count'),
          },
          onValueChanged: (value) {
            setState(() {
              displayMode = value;
            });
          },
        ),
      ),
    ];
    double chartSize = MediaQuery.of(context).size.width / 2;
    List<Widget> charts = [];
    List<Widget> bars = [];
    for (int i = 0; i < 2; i++) {
      if (ids[i] != null) {
        charts.add(PieChart(
          PieChartData(
            sections: getChartData(i),
            centerSpaceRadius: (chartSize * 0.4) - PIE_THICKNESS,
            sectionsSpace: 0,
            startDegreeOffset: 270,
            borderData: FlBorderData(show: false),
          ),
        ));
        bars.add(Column(
          children: splits[i].keys.where((bid) => splits[i][bid].count > 0).map((bid) {
            double statDouble;
            String statString;
            switch (displayMode) {
              case DisplayMode.madePercentage:
                statDouble = splits[i][bid].madePct;
                statString = decimalFormat.format(splits[i][bid].madePct * 100) + '%';
                break;
              case DisplayMode.made:
                statDouble = splits[i][bid].made / totalMade[i];
                statString = splits[i][bid].made.toString();
                break;
              case DisplayMode.count:
                statDouble = splits[i][bid].count / totalBids[i];
                statString = splits[i][bid].count.toString();
                break;
            }
            return Padding(
              padding: EdgeInsets.fromLTRB(0, 2, 0, 2),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(bid.toString(), style: textTheme.bodyText2),
                      Spacer(),
                      Text(statString, style: textTheme.bodyText2),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(height: 12, color: BID_COLORS[bid]),
                        flex: (statDouble * 1000).toInt(),
                      ),
                      Expanded(
                        child: Container(height: 12, color: Colors.grey),
                        flex: ((1 - statDouble) * 1000).toInt(),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ));
      }
    }
    if (isCompare) {
      children.add(Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: charts[0],
                ),
                Expanded(
                  child: charts[1],
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: bars[0],
                ),
                SizedBox(width: 16),
                Expanded(
                  child: bars[1],
                ),
              ],
            ),
          ],
        ),
      ));
    } else {
      children.add(Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: charts[0],
            ),
            SizedBox(width: 16),
            Expanded(
              child: bars[0],
            ),
          ],
        ),
      ));
    }
    children.add(Divider());
    return Column(children: children);
  }

  getSplits() {
    totalMade = [0, 0];
    totalBids = [0, 0];
    splits = [];
    for (int i = 0; i < 2; i++) {
      String id = i == 0 ? id1 : id2;
      if (id == null) {
        continue;
      }
      splits.add(data.statsDb.getBiddingSplits(
        id,
        numRecent: numRecentBids,
        includeArchived: DataStore.displayArchivedStats,
      ));
      for (int bid in Round.ALL_BIDS) {
        totalMade[i] += splits[i][bid].made;
        totalBids[i] += splits[i][bid].count;
      }
    }
  }

  List<PieChartSectionData> getChartData(int i) {
    List<PieChartSectionData> chartData = [];
    for (int bid in Round.ALL_BIDS) {
      double statDouble;
      switch (displayMode) {
        case DisplayMode.madePercentage:
          statDouble = 0;
          if (splits[i][bid].count > 0) {
            statDouble = splits[i][bid].madePct * 1000;
          }
          break;
        case DisplayMode.made:
          statDouble = splits[i][bid].made / totalMade[i];
          break;
        case DisplayMode.count:
          statDouble = splits[i][bid].count / totalBids[i];
          break;
      }

      chartData.add(PieChartSectionData(
        value: statDouble,
        color: BID_COLORS[bid],
        radius: PIE_THICKNESS,
        title: bid.toString(),
        showTitle: false,
      ));
    }
    return chartData;
  }
}

enum DisplayMode {
  madePercentage,
  made,
  count,
}
