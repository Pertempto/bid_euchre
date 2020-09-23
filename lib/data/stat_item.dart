import 'dart:math';

import 'package:intl/intl.dart' as intl;

import 'record.dart';
import 'stat_type.dart';

abstract class StatItem {
  String _entityId;

  String get entityId {
    return _entityId;
  }

  double sortValue;
  String statName;

  StatItem();

  factory StatItem.empty(String entityId, StatType statType) {
    switch (statType) {
      case StatType.overallRating:
        return OverallRatingStatItem(entityId, 0);
      case StatType.bidderRating:
        return BidderRatingStatItem(entityId, 0);
      case StatType.record:
        return WinLossRecordStatItem(entityId, Record(0, 0));
      case StatType.biddingRecord:
        return BiddingRecordStatItem(entityId, Record(0, 0));
      case StatType.recentRecord:
        return RecentRecordStatItem(entityId, Record(0, 0));
      case StatType.winningPercentage:
        return WinningPercentageStatItem(entityId, 0);
      case StatType.madeBidPercentage:
        return MadeBidPercentageStatItem(entityId, 0);
      case StatType.noPartnerMadePercentage:
        return NoPartnerMadePercentageStatItem(entityId, 0);
      case StatType.biddingFrequency:
        return BiddingFrequencyStatItem(entityId, 0);
      case StatType.noPartnerFrequency:
        return NoPartnerFrequencyStatItem(entityId, 0);
      case StatType.pointsPerBid:
        return PointsPerBidStatItem(entityId, 0, 0);
      case StatType.averageBid:
        return AverageBidStatItem(entityId, 0, 0);
      case StatType.streak:
        return StreakStatItem(entityId, 0);
      case StatType.numGames:
        return NumGamesStatItem(entityId, 0);
      case StatType.numRounds:
        return NumRoundsStatItem(entityId, 0);
      case StatType.numBids:
        return NumBidsStatItem(entityId, 0);
      case StatType.numPoints:
        return NumPointsStatItem(entityId, 0);
      case StatType.lastPlayed:
        return LastPlayedStatItem(entityId, 0);
    }
    throw Exception('Invalid stat type: $statType');
  }

  factory StatItem.fromGamesStats(String entityId, StatType statType, List<Map> gamesStats) {
    switch (statType) {
      case StatType.overallRating:
        return OverallRatingStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.bidderRating:
        return BidderRatingStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.record:
        return WinLossRecordStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.biddingRecord:
        return BiddingRecordStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.recentRecord:
        return RecentRecordStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.winningPercentage:
        return WinningPercentageStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.madeBidPercentage:
        return MadeBidPercentageStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.noPartnerMadePercentage:
        return NoPartnerMadePercentageStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.biddingFrequency:
        return BiddingFrequencyStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.noPartnerFrequency:
        return NoPartnerFrequencyStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.pointsPerBid:
        return PointsPerBidStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.averageBid:
        return AverageBidStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.streak:
        return StreakStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.numGames:
        return NumGamesStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.numRounds:
        return NumRoundsStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.numBids:
        return NumBidsStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.numPoints:
        return NumPointsStatItem.fromGamesStats(entityId, gamesStats);
      case StatType.lastPlayed:
        return LastPlayedStatItem.fromGamesStats(entityId, gamesStats);
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
      case StatType.recentRecord:
        return 'Recent Record';
    }
    return '';
  }
}

abstract class DoubleStatItem extends StatItem {
  double _value;

  double get sortValue => -_value;

  DoubleStatItem(String entityId, double value) {
    _entityId = entityId;
    _value = value;
  }
}

abstract class RatingStatItem extends DoubleStatItem {
  double get rating {
    return _value;
  }

  RatingStatItem(String entityId, double rating) : super(entityId, rating);

  @override
  String toString() {
    return _value.toStringAsFixed(1);
  }
}

class OverallRatingStatItem extends RatingStatItem {
  String get statName => 'Overall Rating';

  OverallRatingStatItem(String entityId, double overallRating) : super(entityId, overallRating);

  factory OverallRatingStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    List<Map> recentGamesStats = RecentRecordStatItem.getRecentGamesStats(gamesStats);
    return OverallRatingStatItem(entityId, calculateOverallRating(recentGamesStats, entityId.contains(' ')));
  }

  static double calculateOverallRating(List<Map> gamesStats, bool isTeam) {
    double bidderRating = BidderRatingStatItem.calculateBidderRating(gamesStats, isTeam);
    Record record = WinLossRecordStatItem.calculateRecord(gamesStats);
    double winningRating = 50;
    if (record.totalGames != 0) {
      winningRating = record.winningPercentage * 100;
    }
    double ovr = bidderRating * 0.7 + winningRating * 0.3;
    return ovr;
  }
}

class BidderRatingStatItem extends RatingStatItem {
  String get statName => 'Bidder Rating';

  BidderRatingStatItem(String entityId, double bidderRating) : super(entityId, bidderRating);

  factory BidderRatingStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    List<Map> recentGamesStats = RecentRecordStatItem.getRecentGamesStats(gamesStats);
    return BidderRatingStatItem(entityId, calculateBidderRating(recentGamesStats, entityId.contains(' ')));
  }

  static double calculateBidderRating(List<Map> gamesStats, bool isTeam) {
    int numBids = combineStat(gamesStats, 'numBids');
    int numRounds = combineStat(gamesStats, 'numRounds');
    if (numRounds == 0) {
      return 0;
    }
    double biddingPointsPerRound = 0;
    if (numBids != 0) {
      double ppb = combineStat(gamesStats, 'pointsOnBids') / numBids;
      biddingPointsPerRound = ppb * numBids / numRounds;
    }
    double rating;
    if (isTeam) {
      rating = biddingPointsPerRound / 3.0 * 100;
    } else {
      rating = biddingPointsPerRound / 1.5 * 100;
    }
    return rating;
  }
}

abstract class PercentageStatItem extends DoubleStatItem {
  PercentageStatItem(String entityId, double percentage) : super(entityId, percentage);

  @override
  String toString() {
    return (_value * 100).toStringAsFixed(1) + '%';
  }
}

class WinningPercentageStatItem extends PercentageStatItem {
  String get statName => 'Winning Percentage';

  WinningPercentageStatItem(String entityId, double winningPercentage) : super(entityId, winningPercentage);

  factory WinningPercentageStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    Record record = WinLossRecordStatItem.calculateRecord(gamesStats);
    return WinningPercentageStatItem(entityId, record.winningPercentage);
  }
}

class MadeBidPercentageStatItem extends PercentageStatItem {
  String get statName => 'Made Bid Percentage';

  MadeBidPercentageStatItem(String entityId, double madeBidPercentage) : super(entityId, madeBidPercentage);

  factory MadeBidPercentageStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    int numBids = combineStat(gamesStats, 'numBids');
    double madeBidPercentage = 0;
    if (numBids != 0) {
      madeBidPercentage = combineStat(gamesStats, 'madeBids') / numBids;
    }
    return MadeBidPercentageStatItem(entityId, madeBidPercentage);
  }
}

class NoPartnerMadePercentageStatItem extends PercentageStatItem {
  String get statName => 'Slider/Loner Made %';

  NoPartnerMadePercentageStatItem(String entityId, double noPartnerMadePercentage)
      : super(entityId, noPartnerMadePercentage);

  factory NoPartnerMadePercentageStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    double noPartnerMadePercentage = 0;
    int numNoPartnerBids = combineStat(gamesStats, 'noPartner');
    if (numNoPartnerBids != 0) {
      noPartnerMadePercentage = combineStat(gamesStats, 'madeNoPartner') / numNoPartnerBids;
    }
    return NoPartnerMadePercentageStatItem(entityId, noPartnerMadePercentage);
  }
}

abstract class FrequencyStatItem extends DoubleStatItem {
  FrequencyStatItem(String entityId, double frequencyValue) : super(entityId, frequencyValue);

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

  BiddingFrequencyStatItem(String entityId, double biddingFrequency) : super(entityId, biddingFrequency);

  factory BiddingFrequencyStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    int numRounds = combineStat(gamesStats, 'numRounds');
    int numBids = combineStat(gamesStats, 'numBids');
    double biddingFrequency = 0;
    if (numRounds != 0) {
      biddingFrequency = numBids / numRounds;
    }
    return BiddingFrequencyStatItem(entityId, biddingFrequency);
  }
}

class NoPartnerFrequencyStatItem extends FrequencyStatItem {
  String get statName => 'Slider/Loner Frequency';

  NoPartnerFrequencyStatItem(String entityId, double noPartnerFrequency) : super(entityId, noPartnerFrequency);

  factory NoPartnerFrequencyStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    int numBids = combineStat(gamesStats, 'numBids');
    double noPartnerFrequency = 0;
    if (numBids != 0) {
      noPartnerFrequency = combineStat(gamesStats, 'noPartner') / numBids;
    }
    return NoPartnerFrequencyStatItem(entityId, noPartnerFrequency);
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

  RecordStatItem(String entityId, Record record) {
    _entityId = entityId;
    _record = record;
  }

  @override
  String toString() {
    return record.toString();
  }
}

class WinLossRecordStatItem extends RecordStatItem {
  String get statName => 'Win/Loss Record';

  WinLossRecordStatItem(String entityId, Record winLossRecord) : super(entityId, winLossRecord);

  factory WinLossRecordStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    return WinLossRecordStatItem(entityId, calculateRecord(gamesStats));
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

  BiddingRecordStatItem(String entityId, Record biddingRecord) : super(entityId, biddingRecord);

  factory BiddingRecordStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    int made = combineStat(gamesStats, 'madeBids');
    int set = combineStat(gamesStats, 'numBids') - made;
    return BiddingRecordStatItem(entityId, Record(made, set));
  }
}

class RecentRecordStatItem extends RecordStatItem {
  static const int NUM_RECENT_GAMES = 20;

  String get statName => 'Recent Record';

  RecentRecordStatItem(String entityId, Record recentRecord) : super(entityId, recentRecord);

  factory RecentRecordStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    List<Map> recentGamesStats = getRecentGamesStats(gamesStats);
    return RecentRecordStatItem(entityId, WinLossRecordStatItem.calculateRecord(recentGamesStats));
  }

  static List<Map> getRecentGamesStats(List<Map> gamesStats) {
    return gamesStats.sublist(max(0, gamesStats.length - NUM_RECENT_GAMES), gamesStats.length);
  }
}

abstract class AverageStatItem extends StatItem {
  int _sum, _count;

  int get sum => _sum;

  int get count => _count;

  double get average => sum / count;

  double get sortValue => count == 0 ? double.infinity : -average;

  AverageStatItem(String entityId, int sum, int count) {
    _entityId = entityId;
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

  PointsPerBidStatItem(String entityId, int totalPoints, int numBids) : super(entityId, totalPoints, numBids);

  factory PointsPerBidStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    return PointsPerBidStatItem(entityId, combineStat(gamesStats, 'pointsOnBids'), combineStat(gamesStats, 'numBids'));
  }
}

class AverageBidStatItem extends AverageStatItem {
  String get statName => 'Average Bid';

  AverageBidStatItem(String entityId, int totalBids, int numBids) : super(entityId, totalBids, numBids);

  factory AverageBidStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    return AverageBidStatItem(entityId, combineStat(gamesStats, 'biddingTotal'), combineStat(gamesStats, 'numBids'));
  }
}

class StreakStatItem extends StatItem {
  int _streak;

  int get streak => _streak;

  double get sortValue => -_streak.toDouble();

  String get statName => 'Streak';

  StreakStatItem(String entityId, int streak) {
    _entityId = entityId;
    _streak = streak;
  }

  factory StreakStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    return StreakStatItem(entityId, calculateStreak(gamesStats));
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

  IntStatItem(String entityId, int value) {
    _entityId = entityId;
    _value = value;
  }

  @override
  String toString() {
    return _value.toString();
  }
}

class NumGamesStatItem extends IntStatItem {
  String get statName => 'Number of Games';

  NumGamesStatItem(String entityId, int numGames) : super(entityId, numGames);

  factory NumGamesStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    return NumGamesStatItem(entityId, combineStat(gamesStats, 'numGames'));
  }
}

class NumRoundsStatItem extends IntStatItem {
  String get statName => 'Number of Rounds';

  NumRoundsStatItem(String entityId, int numRounds) : super(entityId, numRounds);

  factory NumRoundsStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    return NumRoundsStatItem(entityId, combineStat(gamesStats, 'numRounds'));
  }
}

class NumBidsStatItem extends IntStatItem {
  String get statName => 'Number of Bids';

  NumBidsStatItem(String entityId, int numBids) : super(entityId, numBids);

  factory NumBidsStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    return NumBidsStatItem(entityId, combineStat(gamesStats, 'numBids'));
  }
}

class NumPointsStatItem extends IntStatItem {
  String get statName => 'Number of Points';

  NumPointsStatItem(String entityId, int numPoints) : super(entityId, numPoints);

  factory NumPointsStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    return NumPointsStatItem(entityId, combineStat(gamesStats, 'numPoints'));
  }
}

class LastPlayedStatItem extends IntStatItem {
  int get lastPlayedTimestamp => _value;

  String get statName => 'Last Played';

  LastPlayedStatItem(String entityId, int lastPlayed) : super(entityId, lastPlayed);

  factory LastPlayedStatItem.fromGamesStats(String entityId, List<Map> gamesStats) {
    return LastPlayedStatItem(entityId, gamesStats.last['lastPlayed']);
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
    combinedStatValue += gameStatMap[statName];
  }
  return combinedStatValue;
}
