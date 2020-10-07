import 'game.dart';

class BiddingSplit {
  List<Round> rounds;

  BiddingSplit(this.rounds);

  double get avgPoints {
    if (count == 0) {
      return double.nan;
    }
    return rounds.map((r) => r.score[r.bidderIndex % 2]).reduce((a, b) => a + b) / count;
  }

  double get avgTricks {
    if (count == 0) {
      return double.nan;
    }
    return rounds.map((r) => r.wonTricks).reduce((a, b) => a + b) / count;
  }

  int get count {
    return rounds.length;
  }

  int get made {
    return rounds.where((r) => r.madeBid).length;
  }

  double get madePct {
    if (count == 0) {
      return double.nan;
    }
    return made / count;
  }
}
