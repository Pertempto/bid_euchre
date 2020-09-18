import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/stats.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OverviewSection extends StatefulWidget {
  final String id;

  OverviewSection(this.id);

  @override
  _OverviewSectionState createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection>
    with AutomaticKeepAliveClientMixin<OverviewSection>, SingleTickerProviderStateMixin {
  String id;
  Data data;

  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    id = widget.id;
    data = DataStore.lastData;
    TextTheme textTheme = Theme.of(context).textTheme;
    TextStyle titleStyle = textTheme.bodyText2.copyWith(fontWeight: FontWeight.w500);
    TextStyle statStyle = textTheme.bodyText2;
    StatItem overallRating = data.statsDb.getStat(id, StatType.overallRating);
    StatItem bidderRating = data.statsDb.getStat(id, StatType.bidderRating);
    Record recentRecord = data.statsDb.getStat(id, StatType.recentRecord).statValue as Record;
    List<Widget> children = [
      ListTile(
        title: Text('Overview', style: textTheme.headline6),
        dense: true,
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Text('Overall Rating', style: titleStyle),
            Spacer(),
            Text(overallRating.toString(), style: statStyle, textAlign: TextAlign.end),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 2, 16, 4),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(height: 4, color: data.statsDb.getEntityColor(id)),
              flex: (overallRating.statValue * 10).round(),
            ),
            Expanded(
              child: Container(height: 4),
              flex: ((100 - overallRating.statValue) * 10).round(),
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Text('Bidder Rating', style: titleStyle),
            Spacer(),
            Text(bidderRating.toString(), style: statStyle, textAlign: TextAlign.end),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 2, 16, 4),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(height: 4, color: data.statsDb.getEntityColor(id)),
              flex: (bidderRating.statValue * 10).round(),
            ),
            Expanded(
              child: Container(height: 4),
              flex: ((100 - bidderRating.statValue) * 10).round(),
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Text('Recent Record', style: titleStyle),
            Spacer(),
            Text(recentRecord.toString(), style: statStyle, textAlign: TextAlign.end),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 2, 16, 4),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(height: 4, color: data.statsDb.getEntityColor(id)),
              flex: recentRecord.wins,
            ),
            Expanded(
              child: Container(height: 4),
              flex: recentRecord.losses,
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text('Streak', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.streak).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Record', style: titleStyle), flex: 5),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.record).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 3,
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text('Games', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.numGames).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Rounds', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.numRounds).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text('Bids', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.numBids).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Points', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.numPoints).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
          ],
        ),
      ),
    ];
    children.add(Divider());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
