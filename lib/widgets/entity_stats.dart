import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'bidding_section.dart';
import 'bidding_splits_section.dart';
import 'trends_section.dart';

class EntityStats extends StatefulWidget {
  final String id;

  EntityStats(this.id);

  @override
  _EntityStatsState createState() => _EntityStatsState();
}

class _EntityStatsState extends State<EntityStats> with AutomaticKeepAliveClientMixin<EntityStats> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    String id = widget.id;
    List<Widget> children = [
      SizedBox(height: 8), // balance out dividers
      BiddingSection(id),
      BiddingSplitsSection(id),
      TrendsSection(id),
      SizedBox(height: 64),
    ];
    return SingleChildScrollView(child: Column(children: children));
  }
}
