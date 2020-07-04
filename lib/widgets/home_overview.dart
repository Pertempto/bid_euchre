import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/player.dart';
import 'package:bideuchre/data/user.dart';
import 'package:bideuchre/widgets/player_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'player_selection.dart';

class HomeOverview extends StatefulWidget {
  HomeOverview();

  @override
  _HomeOverviewState createState() => _HomeOverviewState();
}

class _HomeOverviewState extends State<HomeOverview> {
  Data data;
  TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    data = DataStore.lastData;
    textTheme = Theme.of(context).textTheme;

    List<Widget> children = [
      SizedBox(height: 8),
      notificationsSection(),
      pinnedPlayersSection(),
    ];

    return SingleChildScrollView(child: Column(children: children));
  }

  Widget notificationsSection() {
    List<Widget> children = [
      ListTile(
        title: Text('Notifications', style: textTheme.headline6),
        dense: true,
      ),
    ];
    for (String userId in data.friendsDb.getRequestingFriendIds(data.currentUser.userId)) {
      children.add(ListTile(
        title: Text('${data.users[userId].name} wants to be your friend!', style: textTheme.subtitle1),
        trailing: Icon(Icons.person),
        dense: true,
      ));
    }
    children.add(Divider());

    return Column(children: children);
  }

  Widget pinnedPlayersSection() {
    List<Widget> children = [
      ListTile(
        title: Text('Pinned Players', style: textTheme.headline6),
        trailing: Icon(Icons.add),
        dense: true,
        onTap: () {
          addPinnedPlayer();
        },
      ),
    ];
    for (String playerId in data.currentUser.pinnedPlayerIds) {
      Player player = data.players[playerId];
      if (player != null) {
        children.add(ListTile(
          title: Text(player.fullName, style: textTheme.subtitle1),
          trailing: Icon(MdiIcons.pin),
          dense: true,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerProfile(player)));
          },
        ));
      }
    }
    children.add(Divider());

    return Column(children: children);
  }

  addPinnedPlayer() async {
    String playerId =
        await Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerSelection(hidePinned: true)));
    User user = data.currentUser;
    if (playerId != null && !user.pinnedPlayerIds.contains(playerId)) {
      setState(() {
        user.pinnedPlayerIds.add(playerId);
        user.updateFirestore();
      });
    }
  }
}
