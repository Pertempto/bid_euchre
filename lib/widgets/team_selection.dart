import 'package:bideuchre/data/data_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../util.dart';

class TeamSelection extends StatefulWidget {
  TeamSelection();

  @override
  _TeamSelectionState createState() => _TeamSelectionState();
}

class _TeamSelectionState extends State<TeamSelection> {
  Data data;
  String filterText = '';
  List<String> filteredTeams;
  TextTheme textTheme;
  Map<String, String> teamNames;

  @override
  Widget build(BuildContext context) {
    data = DataStore.lastData;
    if (filteredTeams == null) {
      filteredTeams = data.statsDb.getTeamIds(data.players.keys.toSet());
      teamNames = {};
      for (String teamId in filteredTeams) {
        teamNames[teamId] = Util.teamName(teamId, data);
      }
    }
    filteredTeams.sort((a, b) {
      return teamNames[a].compareTo(teamNames[b]);
    });
    textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Team'),
      ),
      body: ListView.builder(
        itemCount: filteredTeams.length + 2,
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
                ],
              ),
            );
          } else if (index == filteredTeams.length + 1) {
            return SizedBox(height: 16);
          } else {
            String teamId = filteredTeams[index - 1];
            return ListTile(
              dense: true,
              title: Text(teamNames[teamId], style: textTheme.headline6.copyWith(fontWeight: FontWeight.normal)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                Navigator.pop(context, teamId);
              },
            );
          }
        },
      ),
    );
  }

  void onFilterTextChanged(String text) async {
    filterText = text;
    filteredTeams.clear();
    data.statsDb.getTeamIds(data.players.keys.toSet()).forEach((teamId) {
      String lowerTeamName = teamNames[teamId].toLowerCase();
      bool matches = true;
      for (String word in text.toLowerCase().split(' ')) {
        if (!lowerTeamName.contains(word)) {
          matches = false;
        }
      }
      if (text.isEmpty || matches) {
        filteredTeams.add(teamId);
      }
    });
    setState(() {});
  }
}
