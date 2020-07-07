import 'package:bideuchre/data/data_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'games_list.dart';

class GamesPage extends StatefulWidget {
  GamesPage();

  @override
  _GamesPageState createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  @override
  Widget build(BuildContext context) {
    return DataStore.dataWrap((data) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Games'),
            bottom: TabBar(
              tabs: <Widget>[
                Tab(icon: Icon(Icons.person), text: 'Mine'),
                Tab(icon: Icon(Icons.people), text: 'Friends'),
              ],
            ),
          ),
          body: TabBarView(
            children: <Widget>[
              GamesList(false),
              GamesList(true),
            ],
          ),
        ),
      );
    });
  }
}
