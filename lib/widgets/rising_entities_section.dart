import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/stat_item.dart';
import 'package:bideuchre/data/stat_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../util.dart';
import 'player_profile.dart';
import 'team_profile.dart';

class RisingEntitiesSection extends StatefulWidget {
  final bool teams;

  RisingEntitiesSection(this.teams);

  @override
  _RisingEntitiesSectionState createState() => _RisingEntitiesSectionState();
}

class _RisingEntitiesSectionState extends State<RisingEntitiesSection>
    with AutomaticKeepAliveClientMixin<RisingEntitiesSection> {
  static const int NUM_TO_SHOW = 5;
  bool teams;
  TextTheme textTheme;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    teams = widget.teams;
    textTheme = Theme.of(context).textTheme;
    return DataStore.dataWrap((data) {
      List<String> ids;
      if (teams) {
        ids = data.statsDb.getTeamIds(data.players.keys.toSet());
      } else {
        ids = data.players.keys.toList();
      }
      // TODO: extract into function, duplicated from StatsList
      ids = ids.where((id) {
        bool has3Games = (data.statsDb.getStat(id, StatType.numGames) as IntStatItem).value >= 3;
        DateTime lastPlayed = DateTime.fromMillisecondsSinceEpoch(
            (data.statsDb.getStat(id, StatType.lastPlayed) as LastPlayedStatItem).lastPlayedTimestamp);
        bool playedIn10Days = DateTime.now().subtract(Duration(days: 10)).isBefore(lastPlayed);
        return has3Games && playedIn10Days;
      }).toList();
      Map<String, String> names = {};
      if (teams) {
        names = Map.fromIterable(ids, key: (id) => id, value: (id) => Util.teamName(id, data));
      } else {
        names = Map.fromIterable(ids,
            key: (id) => id,
            value: (id) {
              return data.players[id].fullName;
            });
      }
      Map<String, OverallRatingStatItem> veryRecentRatings = {};
      for (String id in ids) {
        List<Map> rawGamesStats = data.statsDb.getEntityRawGamesStats(id);
        rawGamesStats = rawGamesStats.sublist(rawGamesStats.length - 3, rawGamesStats.length);
        veryRecentRatings[id] = OverallRatingStatItem.fromGamesStats(rawGamesStats, teams);
      }
      ids.sort((a, b) {
        int statCmp = veryRecentRatings[a].sortValue.compareTo(veryRecentRatings[b].sortValue);
        if (statCmp != 0) {
          return statCmp;
        }
        return names[a].compareTo(names[b]);
      });

      List<Widget> children = [
        ListTile(
          title: Text(teams ? 'Teams to Beat' : 'Players to Beat', style: textTheme.headline6),
          dense: true,
        ),
      ];
      int placeNum = 0;
      int playerNum = 0;
      double lastSortValue;
      for (String id in ids) {
        StatItem statItem = veryRecentRatings[id];
        playerNum++;
        if (statItem.sortValue != lastSortValue) {
          placeNum = playerNum;
          lastSortValue = statItem.sortValue;
        }
        if (placeNum > NUM_TO_SHOW) {
          break;
        }
        Color color = data.statsDb.getEntityColor(id);
        children.add(GestureDetector(
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 4, 16, 4),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 40,
                  child: Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text(
                      '$placeNum.',
                      style: textTheme.bodyText1.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(names[id], style: textTheme.bodyText1.copyWith(color: color)),
                  flex: 4,
                ),
                Expanded(
                  child: Text(
                    statItem.toString(),
                    style: textTheme.bodyText1.copyWith(fontWeight: FontWeight.w300),
                    textAlign: TextAlign.end,
                  ),
                  flex: 4,
                ),
              ],
            ),
          ),
          onTap: () {
            if (teams) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => TeamProfile(id)));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerProfile(data.players[id])));
            }
          },
        ));
        children.add(Divider());
      }
      // children.add(SizedBox(height: 32));
      // children.add(Divider());
      return Column(children: children);
    });
  }
}
