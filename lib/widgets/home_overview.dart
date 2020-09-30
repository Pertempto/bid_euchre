import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/player.dart';
import 'package:bideuchre/data/user.dart';
import 'package:bideuchre/widgets/player_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'player_selection.dart';
import 'rising_entities_section.dart';

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
      RisingEntitiesSection(false),
      RisingEntitiesSection(true),
      SizedBox(height: 8),
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
    int count = 0;
    for (String groupId in data.relationshipsDb.getGroupInvitations(data.currentUser.userId)) {
      String groupName = data.relationshipsDb.getGroup(groupId).name;
      children.add(ListTile(
        title: Text('You\'ve been invited to join $groupName!', style: textTheme.subtitle1),
        trailing: Icon(MdiIcons.accountGroup),
        dense: true,
      ));
      count++;
    }
    children.add(Divider());

    if (count > 0) {
      return Column(children: children);
    } else {
      return Container();
    }
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
      Color color = data.statsDb.getEntityColor(playerId);
      if (player != null) {
        children.add(ListTile(
          title: Text(player.fullName, style: textTheme.bodyText1.copyWith(color: color)),
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
    Player player =
        await Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerSelection(hidePinned: true)));
    User user = data.currentUser;
    if (player != null && !user.pinnedPlayerIds.contains(player.playerId)) {
      setState(() {
        user.pinnedPlayerIds.add(player.playerId);
        user.updateFirestore();
      });
    }
  }
}
