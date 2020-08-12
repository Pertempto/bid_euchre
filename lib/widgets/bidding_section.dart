import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/stats.dart';
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
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text('Bidder Rating', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.bidderRating).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Made-Set', style: titleStyle), flex: 5),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.biddingRecord).toString(),
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
            Expanded(child: Text('Setting %', style: titleStyle), flex: 5),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.settingPct).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 3,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Bidding Freq.', style: titleStyle), flex: 5),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.biddingFrequency).toString(),
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
            Expanded(child: Text('Average Bid', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.averageBid).toString(),
                  style: statStyle, textAlign: TextAlign.end),
              flex: 2,
            ),
            Expanded(child: Container(), flex: 1),
            Expanded(child: Text('Points Per Bid', style: titleStyle), flex: 6),
            Expanded(
              child: Text(data.statsDb.getStat(id, StatType.pointsPerBid).toString(),
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
