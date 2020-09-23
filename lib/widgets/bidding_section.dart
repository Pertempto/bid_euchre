import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/stat_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BiddingSection extends StatefulWidget {
  final String id;

  BiddingSection(this.id);

  @override
  _BiddingSectionState createState() => _BiddingSectionState();
}

class _BiddingSectionState extends State<BiddingSection>
    with AutomaticKeepAliveClientMixin<BiddingSection>, SingleTickerProviderStateMixin {
  String id;
  Data data;
  bool recentGamesOnly = false;

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
    List<Widget> children = [
      ListTile(
        title: Text('Bidding', style: textTheme.headline6),
        dense: true,
      ),
      Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: CupertinoSlidingSegmentedControl(
          groupValue: recentGamesOnly,
          children: {
            true: Text('Recently'),
            false: Text('All Time'),
          },
          onValueChanged: (value) {
            setState(() {
              recentGamesOnly = value;
            });
          },
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text('Made %', style: titleStyle), flex: 6),
            Expanded(
              child: Text(
                  data.statsDb.getStat(id, StatType.madeBidPercentage, recentGamesOnly: recentGamesOnly).toString(),
                  style: statStyle,
                  textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Made-Set', style: titleStyle), flex: 5),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.biddingRecord, recentGamesOnly: recentGamesOnly).toString(),
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
            Expanded(child: Text('Bids', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.numBids, recentGamesOnly: recentGamesOnly).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Bidding Freq.', style: titleStyle), flex: 5),
            Expanded(
              child: Text(
                  data.statsDb.getStat(id, StatType.biddingFrequency, recentGamesOnly: recentGamesOnly).toString(),
                  style: statStyle,
                  textAlign: TextAlign.end),
              flex: 3,
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text('Average Bid', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.averageBid, recentGamesOnly: recentGamesOnly).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Points Per Bid', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.pointsPerBid, recentGamesOnly: recentGamesOnly).toString(),
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
