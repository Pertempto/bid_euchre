import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/stat_item.dart';
import 'package:bideuchre/data/stat_type.dart';
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
    data = DataStore.currentData;
    TextTheme textTheme = Theme.of(context).textTheme;
    TextStyle titleStyle = textTheme.bodyText2.copyWith(fontWeight: FontWeight.w500);
    TextStyle statStyle = textTheme.bodyText2;
    OverallRatingStatItem overallRating =
        data.statsDb.getStat(id, StatType.overallRating, DataStore.displayArchivedStats);
    BidderRatingStatItem bidderRating = data.statsDb.getStat(id, StatType.bidderRating, DataStore.displayArchivedStats);
    WinnerRatingStatItem winnerRating = data.statsDb.getStat(id, StatType.winnerRating, DataStore.displayArchivedStats);
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
              child: Container(height: 4, color: data.statsDb.getColor(id)),
              flex: (overallRating.rating * 10).round(),
            ),
            Expanded(
              child: Container(height: 4),
              flex: ((100 - overallRating.rating) * 10).round(),
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
              child: Container(height: 4, color: data.statsDb.getColor(id)),
              flex: (bidderRating.rating * 10).round(),
            ),
            Expanded(
              child: Container(height: 4),
              flex: ((100 - bidderRating.rating) * 10).round(),
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Text('Winner Rating', style: titleStyle),
            Spacer(),
            Text(winnerRating.toString(), style: statStyle, textAlign: TextAlign.end),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 2, 16, 4),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(height: 4, color: data.statsDb.getColor(id)),
              flex: (winnerRating.rating * 10).round(),
            ),
            Expanded(
              child: Container(height: 4),
              flex: ((100 - winnerRating.rating) * 10).round(),
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text('Recent Rating', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getRecentRating(id, StatType.overallRating).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Record', style: titleStyle), flex: 5),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.record, DataStore.displayArchivedStats).toString(),
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
              child: Text(data.statsDb.getStat(id, StatType.numGames, DataStore.displayArchivedStats).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Rounds', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.numRounds, DataStore.displayArchivedStats).toString(),
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
              child: Text(data.statsDb.getStat(id, StatType.numBids, DataStore.displayArchivedStats).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Points', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.numPoints, DataStore.displayArchivedStats).toString(),
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
