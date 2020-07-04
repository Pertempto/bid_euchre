import 'data/data_store.dart';

class Util {
  static String scoreString(int score) {
    return score < 0 ? '($score)' : '$score';
  }

  static String getTeamName(String teamId, Data data) {
    List<String> playerIds = teamId.split(' ');
    List<String> playerNames = playerIds.map((id) => data.allPlayers[id].shortName).toList();
    playerNames.sort();
    return playerNames.join(' & ');
  }
}
