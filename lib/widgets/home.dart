import 'package:bideuchre/data/data_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'groups.dart';
import 'home_overview.dart';
import 'home_settings.dart';

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
                  text: 'Home',
                ),
                Tab(
                  icon: Icon(MdiIcons.accountGroup),
                  text: 'Groups',
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
              GroupsPage(),
              HomeSettings(),
            ],
          ),
        ),
      );
    }, allowNull: true);
  }
}
