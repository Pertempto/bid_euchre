import 'package:bideuchre/data/data_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'stats_list.dart';

class StatsPage extends StatefulWidget {
  StatsPage();

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  @override
  Widget build(BuildContext context) {
    return DataStore.dataWrap((data) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Stats'),
        ),
        body: StatsList(),
      );
    });
  }
}
