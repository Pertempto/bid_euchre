import 'package:bideuchre/data/data_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/player.dart';

class PlayerSettings extends StatefulWidget {
  final Player player;

  PlayerSettings(this.player);

  @override
  _PlayerSettingsState createState() => _PlayerSettingsState();
}

class _PlayerSettingsState extends State<PlayerSettings> {
  Player player;

  @override
  Widget build(BuildContext context) {
    player = widget.player;
    return DataStore.dataWrap(
      (data) {
        TextTheme textTheme = Theme.of(context).textTheme;
        TextStyle leadingStyle = textTheme.headline6;
        TextStyle trailingStyle = textTheme.headline6.copyWith(fontWeight: FontWeight.w400);
        List<Widget> children = [
          ListTile(
            title: Text('Name', style: leadingStyle),
            trailing: Text('${player.fullName}', style: trailingStyle),
            dense: true,
            onTap: (player.ownerId != data.currentUser.userId)
                ? null
                : () {
                    editName(context);
                  },
          ),
          if (!data.currentUser.pinnedPlayerIds.contains(player.playerId))
            ListTile(
              title: Text('Pin', style: leadingStyle),
              trailing: Icon(MdiIcons.pin),
              dense: true,
              onTap: () {
                data.currentUser.pinnedPlayerIds.add(player.playerId);
                data.currentUser.updateFirestore();
              },
            ),
          if (data.currentUser.pinnedPlayerIds.contains(player.playerId))
            ListTile(
              title: Text('Unpin', style: leadingStyle),
              trailing: Icon(MdiIcons.pinOff),
              dense: true,
              onTap: () {
                data.currentUser.pinnedPlayerIds.remove(player.playerId);
                data.currentUser.updateFirestore();
              },
            ),
        ];
        return SingleChildScrollView(
          child: Column(children: children),
        );
      },
    );
  }

  void editName(BuildContext context) {
    TextEditingController textFieldController = TextEditingController(text: player.fullName);
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
                  player.fullName = name;
                  player.updateFirestore();
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
