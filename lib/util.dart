import 'data/data_store.dart';
import 'data/player.dart';

class Util {
  static String scoreString(int score) {
    return score < 0 ? '($score)' : '$score';
  }

  static String getTeamName(String teamId, Data data) {
    List<Player> players = teamId.split(' ').map((id) => data.allPlayers[id]).toList();
    if (players.contains(null)) {
      return null;
    }
    List<String> playerNames = players.map((p) => p.shortName).toList();
    playerNames.sort();
    return playerNames.join(' & ');
  }

  static String getTeamId(List<String> playerIds) {
    playerIds.sort();
    return playerIds.join(' ');
  }
}
