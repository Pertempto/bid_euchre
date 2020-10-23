class Round {
  static const List<int> ALL_BIDS = [3, 4, 5, 6, 12, 24];

  bool isPlayerSwitch;

  int roundIndex;
  int dealerIndex;
  int bidderIndex;
  int bid;
  int wonTricks;

  int switchingPlayerIndex;
  String newPlayerId;

  Round(this.dealerIndex, this.bidderIndex, this.bid, this.wonTricks) {
    isPlayerSwitch = false;
  }

  Round.empty(this.dealerIndex) {
    isPlayerSwitch = false;
  }

  Round.playerSwitch(this.switchingPlayerIndex, this.newPlayerId) {
    isPlayerSwitch = true;
  }

  Round.fromData(Map roundData) {
    isPlayerSwitch = roundData['isPlayerSwitch'];
    if (isPlayerSwitch == null) {
      isPlayerSwitch = false;
    }
    if (isPlayerSwitch) {
      switchingPlayerIndex = roundData['switchingPlayerIndex'];
      newPlayerId = roundData['newPlayerId'];
    } else {
      dealerIndex = roundData['dealerIndex'] == -1 ? null : roundData['dealerIndex'];
      bidderIndex = roundData['bidderIndex'] == -1 ? null : roundData['bidderIndex'];
      bid = roundData['bid'] == -1 ? null : roundData['bid'];
      wonTricks = roundData['wonPoints'] == -1 ? null : roundData['wonPoints'];
      if (wonTricks == null) {
        wonTricks = roundData['bidderWonHands'];
      }
    }
  }

  Map get dataMap {
    Map roundData = {
      'isPlayerSwitch': isPlayerSwitch,
    };
    if (isPlayerSwitch) {
      roundData['switchingPlayerIndex'] = switchingPlayerIndex;
      roundData['newPlayerId'] = newPlayerId;
    } else {
      roundData['dealerIndex'] = dealerIndex;
      roundData['bidderIndex'] = bidderIndex;
      roundData['bid'] = bid;
      roundData['wonPoints'] = wonTricks;
      roundData['partnerIndex'] = 0;
    }
    return roundData;
  }

  bool get isFinished {
    return isPlayerSwitch || (dealerIndex != null && bidderIndex != null && bid != null && wonTricks != null);
  }

  bool get madeBid {
    if (!isFinished) {
      return false;
    }
    if (bid == 24 || bid == 12) {
      return wonTricks == 6;
    }
    return wonTricks >= bid;
  }

  List<int> get score {
    if (isPlayerSwitch) {
      return null;
    }
    if (wonTricks == null) {
      return [0, 0];
    }
    List<int> score = [0, 0];
    int bidTeam = bidderIndex % 2;
    int oTeam = 1 - bidTeam;
    if (bid == 24 || bid == 12) {
      if (wonTricks == 6) {
        score[bidTeam] = bid;
      } else {
        score[bidTeam] = -bid;
        score[oTeam] = 6 - wonTricks;
      }
    } else {
      if (wonTricks >= bid) {
        score[bidTeam] = wonTricks;
        score[oTeam] = 6 - wonTricks;
      } else {
        score[bidTeam] = -bid;
        score[oTeam] = 6 - wonTricks;
      }
    }
    return score;
  }

  static String bidString(int bid) {
    if (bid == 24) {
      return "Alone";
    } else if (bid == 12) {
      return "Slide";
    } else {
      return bid.toString();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Round &&
          runtimeType == other.runtimeType &&
          isPlayerSwitch == other.isPlayerSwitch &&
          dealerIndex == other.dealerIndex &&
          bidderIndex == other.bidderIndex &&
          bid == other.bid &&
          wonTricks == other.wonTricks &&
          switchingPlayerIndex == other.switchingPlayerIndex &&
          newPlayerId == other.newPlayerId;

  @override
  int get hashCode =>
      isPlayerSwitch.hashCode ^
      dealerIndex.hashCode ^
      bidderIndex.hashCode ^
      bid.hashCode ^
      wonTricks.hashCode ^
      switchingPlayerIndex.hashCode ^
      newPlayerId.hashCode;
}
