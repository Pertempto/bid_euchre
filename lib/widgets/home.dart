import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/widgets/friends.dart';
import 'package:bideuchre/widgets/home_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'home_overview.dart';

class HomePage extends StatefulWidget {
  HomePage();

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return DataStore.dataWrap((data) {
      if (!data.loaded) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Home'),
          ),
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Home'),
            bottom: TabBar(
              tabs: <Widget>[
                Tab(
                  icon: Icon(Icons.home),
                  text: 'Overview',
                ),
                Tab(
                  icon: Icon(Icons.people),
                  text: 'Friends',
                ),
                Tab(
                  icon: Icon(Icons.settings),
                  text: 'Settings',
                )
              ],
            ),
          ),
          body: TabBarView(
            children: <Widget>[
              HomeOverview(),
              FriendsPage(),
              HomeSettings(),
            ],
          ),
        ),
      );
    }, allowNull: true);
  }
}
