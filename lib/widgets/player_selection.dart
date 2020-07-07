import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/player.dart';
import '../data/user.dart';

class PlayerSelection extends StatefulWidget {
  final bool hidePinned;

  PlayerSelection({this.hidePinned = false});

  @override
  _PlayerSelectionState createState() => _PlayerSelectionState();
}

class _PlayerSelectionState extends State<PlayerSelection> {
  Data data;
  String filterText = '';
  List<Player> filteredPlayers;
  TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    data = DataStore.lastData;
    if (filteredPlayers == null) {
      filteredPlayers = List.from(data.players.values);
    }
    User user = data.users[data.currentUser.userId];
    if (widget.hidePinned) {
      filteredPlayers = filteredPlayers.where((p) => !user.pinnedPlayerIds.contains(p.playerId)).toList();
    }
    List<Game> recentGames = data.games.where((g) => g.userId == user.userId && g.isFinished).toList();
    Map<String, int> playersRecent = Map.fromIterable(data.allPlayers.values, key: (p) => p.playerId, value: (p) => 0);
    for (int i = 0; i < recentGames.length && i < 3; i++) {
      for (String playerId in recentGames[i].allPlayerIds) {
        playersRecent[playerId] = 1;
      }
    }
    filteredPlayers.sort((a, b) {
      int aPinned = user.pinnedPlayerIds.contains(a.playerId) ? 0 : 1;
      int bPinned = user.pinnedPlayerIds.contains(b.playerId) ? 0 : 1;
      int pinnedCmp = aPinned.compareTo(bPinned);
      if (pinnedCmp != 0) {
        return pinnedCmp;
      }
      int recentCmp = -playersRecent[a.playerId].compareTo(playersRecent[b.playerId]);
      if (recentCmp != 0) {
        return recentCmp;
      }
      return a.fullName.compareTo(b.fullName);
    });
    textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Player'),
      ),
      body: ListView.builder(
        itemCount: filteredPlayers.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: TextField(
                      decoration: InputDecoration(hintText: 'Filter', prefixIcon: Icon(Icons.search)),
                      onChanged: onFilterTextChanged,
                    ),
                  ),
                  SizedBox(width: 16),
                  OutlineButton.icon(
                    icon: Icon(Icons.person_add),
                    label: Text('New Player'),
                    onPressed: () {
                      newPlayer(context, user, filterText);
                    },
                  )
                ],
              ),
            );
          } else if (index == filteredPlayers.length + 1) {
            return SizedBox(height: 16);
          } else {
            Player player = filteredPlayers[index - 1];
            return ListTile(
              dense: true,
              title: Text(
                player.fullName,
                style: textTheme.headline6.copyWith(fontWeight: FontWeight.normal),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (user.pinnedPlayerIds.contains(player.playerId)) Text('Pinned', style: textTheme.subtitle1),
                  if (!user.pinnedPlayerIds.contains(player.playerId) && playersRecent[player.playerId] >= 1)
                    Text('Recent', style: textTheme.subtitle1),
                  Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                Navigator.pop(context, player);
              },
            );
          }
        },
      ),
    );
  }

  void newPlayer(BuildContext context, User user, String initialName) {
    TextEditingController textFieldController = TextEditingController();
    textFieldController.text = initialName;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('New Player'),
          contentPadding: EdgeInsets.fromLTRB(24, 0, 24, 0),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('Full Name:'),
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
                  Player player = Player.newPlayer(user, name);
                  print('new player: ${player.playerId}');
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(player);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void onFilterTextChanged(String text) async {
    filterText = text;
    filteredPlayers.clear();
    data.players.values.forEach((player) {
      if (text.isEmpty || player.fullName.toLowerCase().contains(text.toLowerCase().trim())) {
        filteredPlayers.add(player);
      }
    });
    setState(() {});
  }
}
