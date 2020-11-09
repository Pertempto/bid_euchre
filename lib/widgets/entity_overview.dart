import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'bidding_section.dart';
import 'games_section.dart';
import 'overview_section.dart';

class EntityOverview extends StatefulWidget {
  final String entityId;

  EntityOverview(this.entityId);

  @override
  _EntityOverviewState createState() => _EntityOverviewState();
}

class _EntityOverviewState extends State<EntityOverview> with AutomaticKeepAliveClientMixin<EntityOverview> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    List<Widget> children = [
      SizedBox(height: 8), // balance out dividers
      OverviewSection(widget.entityId),
      BiddingSection(widget.entityId),
      GamesSection(widget.entityId),
      SizedBox(height: 64),
    ];
    return SingleChildScrollView(child: Column(children: children));
  }
}
