import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'bidding_splits_section.dart';
import 'trends_section.dart';

class EntityGraphs extends StatefulWidget {
  final String id;

  EntityGraphs(this.id);

  @override
  _EntityGraphsState createState() => _EntityGraphsState();
}

class _EntityGraphsState extends State<EntityGraphs> with AutomaticKeepAliveClientMixin<EntityGraphs> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    String id = widget.id;
    List<Widget> children = [
      SizedBox(height: 8), // balance out dividers
      BiddingSplitsSection(id),
      TrendsSection(id),
      SizedBox(height: 64),
    ];
    return SingleChildScrollView(child: Column(children: children));
  }
}
