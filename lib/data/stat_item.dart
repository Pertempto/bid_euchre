import 'package:intl/intl.dart' as intl;

import 'record.dart';
import 'stat_type.dart';

abstract class StatItem {
  double sortValue;
  String statName;

  StatItem();

  factory StatItem.empty(StatType statType) {
    switch (statType) {
      case StatType.overallRating:
        return OverallRatingStatItem(0);
      case StatType.bidderRating:
        return BidderRatingStatItem(0);
      case StatType.record:
        return WinLossRecordStatItem(Record(0, 0));
      case StatType.biddingRecord:
        return BiddingRecordStatItem(Record(0, 0));
      case StatType.winningPercentage:
        return WinningPercentageStatItem(0);
      case StatType.madeBidPercentage:
        return MadeBidPercentageStatItem(0);
      case StatType.noPartnerMadePercentage:
        return NoPartnerMadePercentageStatItem(0);
      case StatType.biddingFrequency:
        return BiddingFrequencyStatItem(0);
      case StatType.noPartnerFrequency:
        return NoPartnerFrequencyStatItem(0);
      case StatType.pointsPerBid:
        return PointsPerBidStatItem(0, 0);
      case StatType.pointsDiffPerBid:
        return PointsDiffPerBidStatItem(0, 0);
      case StatType.averageBid:
        return AverageBidStatItem(0, 0);
      case StatType.streak:
        return StreakStatItem(0);
      case StatType.numGames:
        return NumGamesStatItem(0);
      case StatType.numRounds:
        return NumRoundsStatItem(0);
      case StatType.numBids:
        return NumBidsStatItem(0);
      case StatType.numPoints:
        return NumPointsStatItem(0);
      case StatType.lastPlayed:
        return LastPlayedStatItem(0);
    }
    throw Exception('Invalid stat type: $statType');
  }

  factory StatItem.fromGamesStats(StatType statType, List<Map> gamesStats, bool isTeam) {
    switch (statType) {
      case StatType.overallRating:
        return OverallRatingStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.bidderRating:
        return BidderRatingStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.record:
        return WinLossRecordStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.biddingRecord:
        return BiddingRecordStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.winningPercentage:
        return WinningPercentageStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.madeBidPercentage:
        return MadeBidPercentageStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.noPartnerMadePercentage:
        return NoPartnerMadePercentageStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.biddingFrequency:
        return BiddingFrequencyStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.noPartnerFrequency:
        return NoPartnerFrequencyStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.pointsPerBid:
        return PointsPerBidStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.pointsDiffPerBid:
        return PointsDiffPerBidStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.averageBid:
        return AverageBidStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.streak:
        return StreakStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.numGames:
        return NumGamesStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.numRounds:
        return NumRoundsStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.numBids:
        return NumBidsStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.numPoints:
        return NumPointsStatItem.fromGamesStats(gamesStats, isTeam);
      case StatType.lastPlayed:
        return LastPlayedStatItem.fromGamesStats(gamesStats, isTeam);
    }
    throw Exception('Invalid stat type: $statType');
  }

  // need to figure out a way to get rid of the need for this function
  static String getStatName(StatType statType) {
    switch (statType) {
      case StatType.record:
        return 'Win/Loss Record';
      case StatType.winningPercentage:
        return 'Winning Percentage';
      case StatType.streak:
        return 'Streak';
      case StatType.numGames:
        return 'Number of Games';
      case StatType.numRounds:
        return 'Number of Rounds';
      case StatType.numBids:
        return 'Number of Bids';
      case StatType.numPoints:
        return 'Number of Points';
      case StatType.biddingFrequency:
        return 'Bidding Frequency';
      case StatType.biddingRecord:
        return 'Bidding Record';
      case StatType.madeBidPercentage:
        return 'Made Bid Percentage';
      case StatType.averageBid:
        return 'Average Bid';
      case StatType.pointsPerBid:
        return 'Points Per Bid';
      case StatType.pointsDiffPerBid:
        return 'Points Diff Per Bid';
      case StatType.lastPlayed:
        return 'Last Played';
      case StatType.noPartnerFrequency:
        return 'Slide/Loner Frequency';
      case StatType.noPartnerMadePercentage:
        return 'Slider/Loner Made %';
      case StatType.bidderRating:
        return 'Bidder Rating';
      case StatType.overallRating:
        return 'Overall Rating';
    }
    return '';
  }
}

abstract class DoubleStatItem extends StatItem {
  double _value;

  double get sortValue => -_value;

  DoubleStatItem(double value) {
    _value = value;
  }
}

abstract class RatingStatItem extends DoubleStatItem {
  double get rating {
    return _value;
  }

  RatingStatItem(double rating) : super(rating);

  @override
  String toString() {
    return _value.toStringAsFixed(1);
  }
}

class OverallRatingStatItem extends RatingStatItem {
  String get statName => 'Overall Rating';

  OverallRatingStatItem(double overallRating) : super(overallRating);

  factory OverallRatingStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    return OverallRatingStatItem(calculateOverallRating(gamesStats, isTeam));
  }

  static double calculateOverallRating(List<Map> gamesStats, bool isTeam) {
    double bidderRating = BidderRatingStatItem.calculateBidderRating(gamesStats, isTeam);
    Record record = WinLossRecordStatItem.calculateRecord(gamesStats);
    double winningRating = 0;
    if (record.totalGames != 0) {
      winningRating = record.winningPercentage * 100;
    }
    double ovr = bidderRating * 0.7 + winningRating * 0.3;
    return ovr;
  }
}

class BidderRatingStatItem extends RatingStatItem {
  String get statName => 'Bidder Rating';

  BidderRatingStatItem(double bidderRating) : super(bidderRating);

  factory BidderRatingStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    return BidderRatingStatItem(calculateBidderRating(gamesStats, isTeam));
  }

  static double calculateBidderRating(List<Map> gamesStats, bool isTeam) {
    int numBids = combineStat(gamesStats, 'numBids');
    int numRounds = combineStat(gamesStats, 'numRounds');
    if (numRounds == 0) {
      return 0;
    }
    double biddingPointsPerRound = 0;
    if (numBids != 0) {
      double ppb = combineStat(gamesStats, 'pointsDiffOnBids') / numBids;
      biddingPointsPerRound = ppb * numBids / numRounds;
    }
    double rating;
    if (isTeam) {
      rating = biddingPointsPerRound / 2 * 100;
    } else {
      rating = biddingPointsPerRound / 1 * 100;
    }
    return rating;
  }
}

abstract class PercentageStatItem extends DoubleStatItem {
  PercentageStatItem(double percentage) : super(percentage);

  @override
  String toString() {
    return (_value * 100).toStringAsFixed(1) + '%';
  }
}

class WinningPercentageStatItem extends PercentageStatItem {
  String get statName => 'Winning Percentage';

  WinningPercentageStatItem(double winningPercentage) : super(winningPercentage);

  factory WinningPercentageStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    Record record = WinLossRecordStatItem.calculateRecord(gamesStats);
    return WinningPercentageStatItem(record.winningPercentage);
  }
}

class MadeBidPercentageStatItem extends PercentageStatItem {
  String get statName => 'Made Bid Percentage';

  MadeBidPercentageStatItem(double madeBidPercentage) : super(madeBidPercentage);

  factory MadeBidPercentageStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    int numBids = combineStat(gamesStats, 'numBids');
    double madeBidPercentage = 0;
    if (numBids != 0) {
      madeBidPercentage = combineStat(gamesStats, 'madeBids') / numBids;
    }
    return MadeBidPercentageStatItem(madeBidPercentage);
  }
}

class NoPartnerMadePercentageStatItem extends PercentageStatItem {
  String get statName => 'Slider/Loner Made %';

  NoPartnerMadePercentageStatItem(double noPartnerMadePercentage) : super(noPartnerMadePercentage);

  factory NoPartnerMadePercentageStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    double noPartnerMadePercentage = 0;
    int numNoPartnerBids = combineStat(gamesStats, 'noPartner');
    if (numNoPartnerBids != 0) {
      noPartnerMadePercentage = combineStat(gamesStats, 'madeNoPartner') / numNoPartnerBids;
    }
    return NoPartnerMadePercentageStatItem(noPartnerMadePercentage);
  }
}

abstract class FrequencyStatItem extends DoubleStatItem {
  FrequencyStatItem(double frequencyValue) : super(frequencyValue);

  @override
  String toString() {
    if (_value == 0) {
      return '-';
    }
    String inverseRateString = (1 / _value).toStringAsFixed(1);
    return '1 in $inverseRateString';
  }
}

class BiddingFrequencyStatItem extends FrequencyStatItem {
  String get statName => 'Bidding Frequency';

  BiddingFrequencyStatItem(double biddingFrequency) : super(biddingFrequency);

  factory BiddingFrequencyStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    int numRounds = combineStat(gamesStats, 'numRounds');
    int numBids = combineStat(gamesStats, 'numBids');
    double biddingFrequency = 0;
    if (numRounds != 0) {
      biddingFrequency = numBids / numRounds;
    }
    return BiddingFrequencyStatItem(biddingFrequency);
  }
}

class NoPartnerFrequencyStatItem extends FrequencyStatItem {
  String get statName => 'Slider/Loner Frequency';

  NoPartnerFrequencyStatItem(double noPartnerFrequency) : super(noPartnerFrequency);

  factory NoPartnerFrequencyStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    int numBids = combineStat(gamesStats, 'numBids');
    double noPartnerFrequency = 0;
    if (numBids != 0) {
      noPartnerFrequency = combineStat(gamesStats, 'noPartner') / numBids;
    }
    return NoPartnerFrequencyStatItem(noPartnerFrequency);
  }
}

abstract class RecordStatItem extends StatItem {
  Record _record;

  Record get record => _record;

  double get sortValue {
    if (record.totalGames == 0) {
      return 1;
    }
    return -record.winningPercentage;
  }

  RecordStatItem(Record record) {
    _record = record;
  }

  @override
  String toString() {
    return record.toString();
  }
}

class WinLossRecordStatItem extends RecordStatItem {
  String get statName => 'Win/Loss Record';

  WinLossRecordStatItem(Record winLossRecord) : super(winLossRecord);

  factory WinLossRecordStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    return WinLossRecordStatItem(calculateRecord(gamesStats));
  }

  static Record calculateRecord(List<Map> gamesStats) {
    List<int> recentDiffs = gamesStats.map((gameStats) => gameStats['scoreDiff']).toList().cast<int>();
    int wins = recentDiffs.where((d) => d > 0).length;
    int losses = recentDiffs.where((d) => d < 0).length;
    return Record(wins, losses);
  }
}

class BiddingRecordStatItem extends RecordStatItem {
  String get statName => 'Bidding Record';

  BiddingRecordStatItem(Record biddingRecord) : super(biddingRecord);

  factory BiddingRecordStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    int made = combineStat(gamesStats, 'madeBids');
    int set = combineStat(gamesStats, 'numBids') - made;
    return BiddingRecordStatItem(Record(made, set));
  }
}

abstract class AverageStatItem extends StatItem {
  int _sum, _count;

  int get sum => _sum;

  int get count => _count;

  double get average => sum / count;

  double get sortValue => count == 0 ? double.infinity : -average;

  AverageStatItem(int sum, int count) {
    _sum = sum;
    _count = count;
  }

  @override
  String toString() {
    if (count == 0) {
      return '-';
    }
    return average.toStringAsFixed(2);
  }
}

class PointsPerBidStatItem extends AverageStatItem {
  String get statName => 'Points Per Bid';

  PointsPerBidStatItem(int totalPoints, int numBids) : super(totalPoints, numBids);

  factory PointsPerBidStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    return PointsPerBidStatItem(combineStat(gamesStats, 'pointsOnBids'), combineStat(gamesStats, 'numBids'));
  }
}

class PointsDiffPerBidStatItem extends AverageStatItem {
  String get statName => 'Points Diff Per Bid';

  PointsDiffPerBidStatItem(int totalPoints, int numBids) : super(totalPoints, numBids);

  factory PointsDiffPerBidStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    return PointsDiffPerBidStatItem(combineStat(gamesStats, 'pointsDiffOnBids'), combineStat(gamesStats, 'numBids'));
  }
}

class AverageBidStatItem extends AverageStatItem {
  String get statName => 'Average Bid';

  AverageBidStatItem(int totalBids, int numBids) : super(totalBids, numBids);

  factory AverageBidStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    return AverageBidStatItem(combineStat(gamesStats, 'biddingTotal'), combineStat(gamesStats, 'numBids'));
  }
}

class StreakStatItem extends StatItem {
  int _streak;

  int get streak => _streak;

  double get sortValue => -_streak.toDouble();

  String get statName => 'Streak';

  StreakStatItem(int streak) {
    _streak = streak;
  }

  factory StreakStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    return StreakStatItem(calculateStreak(gamesStats));
  }

  @override
  String toString() {
    if (streak > 0) {
      return '${streak}W';
    } else if (streak < 0) {
      return '${-streak}L';
    }
    return '-';
  }

  static int calculateStreak(List<Map> gamesStats) {
    int streak = 0;
    // iterate through score diffs, newest to oldest
    for (int scoreDiff in gamesStats.map((gameStats) => gameStats['scoreDiff']).toList().reversed) {
      if (scoreDiff > 0) {
        if (streak >= 0) {
          streak++;
        } else {
          break;
        }
      } else {
        if (streak <= 0) {
          streak--;
        } else {
          break;
        }
      }
    }
    return streak;
  }
}

abstract class IntStatItem extends StatItem {
  int _value;

  int get value => _value;

  double get sortValue => -_value.toDouble();

  IntStatItem(int value) {
    _value = value;
  }

  @override
  String toString() {
    return _value.toString();
  }
}

class NumGamesStatItem extends IntStatItem {
  String get statName => 'Number of Games';

  NumGamesStatItem(int numGames) : super(numGames);

  factory NumGamesStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    return NumGamesStatItem(combineStat(gamesStats, 'numGames'));
  }
}

class NumRoundsStatItem extends IntStatItem {
  String get statName => 'Number of Rounds';

  NumRoundsStatItem(int numRounds) : super(numRounds);

  factory NumRoundsStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    return NumRoundsStatItem(combineStat(gamesStats, 'numRounds'));
  }
}

class NumBidsStatItem extends IntStatItem {
  String get statName => 'Number of Bids';

  NumBidsStatItem(int numBids) : super(numBids);

  factory NumBidsStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    return NumBidsStatItem(combineStat(gamesStats, 'numBids'));
  }
}

class NumPointsStatItem extends IntStatItem {
  String get statName => 'Number of Points';

  NumPointsStatItem(int numPoints) : super(numPoints);

  factory NumPointsStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    return NumPointsStatItem(combineStat(gamesStats, 'numPoints'));
  }
}

class LastPlayedStatItem extends IntStatItem {
  int get lastPlayedTimestamp => _value;

  String get statName => 'Last Played';

  LastPlayedStatItem(int lastPlayed) : super(lastPlayed);

  factory LastPlayedStatItem.fromGamesStats(List<Map> gamesStats, bool isTeam) {
    return LastPlayedStatItem(gamesStats.last['lastPlayed']);
  }

  @override
  String toString() {
    if (lastPlayedTimestamp == 0) {
      return '-';
    }
    DateTime date = DateTime.fromMillisecondsSinceEpoch(lastPlayedTimestamp);
    return intl.DateFormat.yMd().add_jm().format(date);
  }
}

int combineStat(List<Map> gamesStats, String statName) {
  int combinedStatValue = 0;
  for (Map gameStatMap in gamesStats) {
    try {
      combinedStatValue += gameStatMap[statName];
    } on NoSuchMethodError {
      throw Exception("Can't find raw stat '$statName'");
    }
  }
  return combinedStatValue;
}
