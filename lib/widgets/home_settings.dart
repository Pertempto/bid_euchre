import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

import '../data/data_store.dart';
import '../data/player.dart';
import '../data/user.dart';

class HomeSettings extends StatefulWidget {
  HomeSettings();

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<HomeSettings> {
  User currentUser;
  Map<String, Player> players;
  String appVersion = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  @override
  Widget build(BuildContext context) {
    Data data = DataStore.lastData;
    currentUser = data.currentUser;
    players = data.players;

    TextTheme textTheme = Theme.of(context).textTheme;
    TextStyle leadingStyle = textTheme.headline6;
    TextStyle trailingStyle = textTheme.headline6.copyWith(fontWeight: FontWeight.w400);
    List<Widget> children = [
      ListTile(
        title: Text('Signed in as ${currentUser.name}', style: leadingStyle),
        dense: true,
        onTap: () {
          editName(context);
        },
      ),
      ListTile(
        title: Text('App Version', style: leadingStyle),
        trailing: Text('v$appVersion', style: trailingStyle),
        dense: true,
      ),
      ListTile(
        trailing: Wrap(
          spacing: 12,
          children: <Widget>[
            OutlineButton.icon(
              icon: Icon(Icons.person),
              label: Text('Sign Out'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Sign Out'),
                      contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                      content: Text('Are you sure?'),
                      actions: <Widget>[
                        FlatButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        FlatButton(
                          child: Text('Sign Out'),
                          onPressed: () {
                            DataStore.auth.signOut();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            OutlineButton.icon(
              icon: Icon(Icons.info),
              label: Text('About'),
              onPressed: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Bid Euchre Scorekeeper',
                  applicationVersion: appVersion,
                  applicationIcon: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: 24,
                    child: Image.asset('assets/logo.png'),
                  ),
                  applicationLegalese: 'Copyright 2020 Addison Emig',
                );
              },
            ),
          ],
        ),
      ),
    ];

    return SingleChildScrollView(child: Column(children: children));
  }

  Future<void> _initPackageInfo() async {
    PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = info.version;
    });
  }

  void editName(BuildContext context) {
    TextEditingController textFieldController = TextEditingController(text: currentUser.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Name'),
          contentPadding: EdgeInsets.fromLTRB(24, 0, 24, 0),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('Name:'),
              ),
              Expanded(
                child: TextField(controller: textFieldController),
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('Submit'),
              onPressed: () {
                String name = textFieldController.value.text.trim();
                if (name.isNotEmpty) {
                  currentUser.name = name;
                  currentUser.updateFirestore();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
