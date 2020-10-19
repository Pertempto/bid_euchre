import 'package:bideuchre/data/entity_raw_game_stats.dart';
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
      case StatType.biddingFrequency:
        return BiddingFrequencyStatItem(0);
      case StatType.gainedPerBid:
        return GainedPerBidStatItem(0, 0);
      case StatType.averageBid:
        return AverageBidStatItem(0, 0);
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

  factory StatItem.fromRawStats(StatType statType, List<EntityRawGameStats> rawStats, bool isTeam) {
    switch (statType) {
      case StatType.overallRating:
        return OverallRatingStatItem.fromRawStats(rawStats, isTeam);
      case StatType.bidderRating:
        return BidderRatingStatItem.fromRawStats(rawStats, isTeam);
      case StatType.record:
        return WinLossRecordStatItem.fromRawStats(rawStats, isTeam);
      case StatType.biddingRecord:
        return BiddingRecordStatItem.fromRawStats(rawStats, isTeam);
      case StatType.winningPercentage:
        return WinningPercentageStatItem.fromRawStats(rawStats, isTeam);
      case StatType.madeBidPercentage:
        return MadeBidPercentageStatItem.fromRawStats(rawStats, isTeam);
      case StatType.biddingFrequency:
        return BiddingFrequencyStatItem.fromRawStats(rawStats, isTeam);
      case StatType.gainedPerBid:
        return GainedPerBidStatItem.fromRawStats(rawStats, isTeam);
      case StatType.averageBid:
        return AverageBidStatItem.fromRawStats(rawStats, isTeam);
      case StatType.numGames:
        return NumGamesStatItem.fromRawStats(rawStats, isTeam);
      case StatType.numRounds:
        return NumRoundsStatItem.fromRawStats(rawStats, isTeam);
      case StatType.numBids:
        return NumBidsStatItem.fromRawStats(rawStats, isTeam);
      case StatType.numPoints:
        return NumPointsStatItem.fromRawStats(rawStats, isTeam);
      case StatType.lastPlayed:
        return LastPlayedStatItem.fromRawStats(rawStats, isTeam);
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
      case StatType.gainedPerBid:
        return 'Gained Per Bid';
      case StatType.lastPlayed:
        return 'Last Played';
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

  factory OverallRatingStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    return OverallRatingStatItem(calculateOverallRating(rawStats, isTeam));
  }

  static double calculateOverallRating(List<EntityRawGameStats> rawStats, bool isTeam) {
    double bidderRating = BidderRatingStatItem.calculateBidderRating(rawStats, isTeam);
    Record record = WinLossRecordStatItem.calculateRecord(rawStats);
    double winningRating = 0;
    if (record.total != 0) {
      winningRating = record.winningPercentage * 100;
    }
    double ovr = bidderRating * 0.5 + winningRating * 0.5;
    return ovr;
  }
}

class BidderRatingStatItem extends RatingStatItem {
  String get statName => 'Bidder Rating';

  BidderRatingStatItem(double bidderRating) : super(bidderRating);

  factory BidderRatingStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    return BidderRatingStatItem(calculateBidderRating(rawStats, isTeam));
  }

  static double calculateBidderRating(List<EntityRawGameStats> rawStats, bool isTeam) {
    int numBids = EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumBids);
    int numRounds = EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumRounds);
    if (numRounds == 0) {
      return 0;
    }
    double gainedPerRound = 0;
    if (numBids != 0) {
      int totalGained = EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.GainedOnBids);
      gainedPerRound = totalGained / numRounds;
    }
    double rating;
    if (isTeam) {
      rating = gainedPerRound / 2 * 100;
    } else {
      rating = gainedPerRound / 1 * 100;
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

  factory WinningPercentageStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    Record record = WinLossRecordStatItem.calculateRecord(rawStats);
    return WinningPercentageStatItem(record.winningPercentage);
  }
}

class MadeBidPercentageStatItem extends PercentageStatItem {
  String get statName => 'Made Bid Percentage';

  MadeBidPercentageStatItem(double madeBidPercentage) : super(madeBidPercentage);

  factory MadeBidPercentageStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    int numBids = EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumBids);
    double madeBidPercentage = 0;
    if (numBids != 0) {
      madeBidPercentage = EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.MadeBids) / numBids;
    }
    return MadeBidPercentageStatItem(madeBidPercentage);
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

  factory BiddingFrequencyStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    int numRounds = EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumRounds);
    int numBids = EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumBids);
    double biddingFrequency = 0;
    if (numRounds != 0) {
      biddingFrequency = numBids / numRounds;
    }
    return BiddingFrequencyStatItem(biddingFrequency);
  }
}

abstract class RecordStatItem extends StatItem {
  Record _record;

  Record get record => _record;

  double get sortValue {
    if (record.total == 0) {
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

  factory WinLossRecordStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    return WinLossRecordStatItem(calculateRecord(rawStats));
  }

  static Record calculateRecord(List<EntityRawGameStats> rawStats) {
    List<bool> recentDiffs =
        rawStats.where((gameStats) => gameStats.isFullGame).map((gameStats) => gameStats.won).toList().cast<bool>();
    int wins = recentDiffs.where((won) => won).length;
    int losses = recentDiffs.where((won) => !won).length;
    return Record(wins, losses);
  }
}

class BiddingRecordStatItem extends RecordStatItem {
  String get statName => 'Bidding Record';

  BiddingRecordStatItem(Record biddingRecord) : super(biddingRecord);

  factory BiddingRecordStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    int made = EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.MadeBids);
    int set = EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumBids) - made;
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

class GainedPerBidStatItem extends AverageStatItem {
  String get statName => 'Gained Points Per Bid';

  GainedPerBidStatItem(int totalGainedPoints, int numBids) : super(totalGainedPoints, numBids);

  factory GainedPerBidStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    return GainedPerBidStatItem(
      EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.GainedOnBids),
      EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumBids),
    );
  }
}

class AverageBidStatItem extends AverageStatItem {
  String get statName => 'Average Bid';

  AverageBidStatItem(int totalBids, int numBids) : super(totalBids, numBids);

  factory AverageBidStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    return AverageBidStatItem(
      EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.BiddingTotal),
      EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumBids),
    );
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

  factory NumGamesStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    return NumGamesStatItem(EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumGames));
  }
}

class NumRoundsStatItem extends IntStatItem {
  String get statName => 'Number of Rounds';

  NumRoundsStatItem(int numRounds) : super(numRounds);

  factory NumRoundsStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    return NumRoundsStatItem(EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumRounds));
  }
}

class NumBidsStatItem extends IntStatItem {
  String get statName => 'Number of Bids';

  NumBidsStatItem(int numBids) : super(numBids);

  factory NumBidsStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    return NumBidsStatItem(EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumBids));
  }
}

class NumPointsStatItem extends IntStatItem {
  String get statName => 'Number of Points';

  NumPointsStatItem(int numPoints) : super(numPoints);

  factory NumPointsStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    return NumPointsStatItem(EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumPoints));
  }
}

class LastPlayedStatItem extends IntStatItem {
  int get lastPlayedTimestamp => _value;

  String get statName => 'Last Played';

  LastPlayedStatItem(int lastPlayed) : super(lastPlayed);

  factory LastPlayedStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    return LastPlayedStatItem(rawStats.last.timestamp);
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
