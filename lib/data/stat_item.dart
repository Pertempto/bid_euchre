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
      case StatType.winnerRating:
        return WinnerRatingStatItem(0);
      case StatType.setterRating:
        return SetterRatingStatItem(0);
      case StatType.record:
        return WinLossRecordStatItem(Record(0, 0));
      case StatType.biddingRecord:
        return BiddingRecordStatItem(Record(0, 0));
      case StatType.winningPercentage:
        return WinningPercentageStatItem(0);
      case StatType.madeBidPercentage:
        return MadeBidPercentageStatItem(0);
      case StatType.biddingOftenness:
        return BiddingOftennessStatItem(0);
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
      case StatType.numBiddingOpportunities:
        return NumBiddingOpportunitiesStatItem(0);
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
        throw Exception('Do not get overall rating this way');
      case StatType.bidderRating:
        throw Exception('Do not get bidder rating this way');
      case StatType.winnerRating:
        throw Exception('Do not get winner rating this way');
      case StatType.setterRating:
        throw Exception('Do not get setter rating this way');
      case StatType.record:
        return WinLossRecordStatItem.fromRawStats(rawStats, isTeam);
      case StatType.biddingRecord:
        return BiddingRecordStatItem.fromRawStats(rawStats, isTeam);
      case StatType.winningPercentage:
        return WinningPercentageStatItem.fromRawStats(rawStats, isTeam);
      case StatType.madeBidPercentage:
        return MadeBidPercentageStatItem.fromRawStats(rawStats, isTeam);
      case StatType.biddingOftenness:
        return BiddingOftennessStatItem.fromRawStats(rawStats, isTeam);
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
      case StatType.numBiddingOpportunities:
        return NumBiddingOpportunitiesStatItem.fromRawStats(rawStats, isTeam);
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
      case StatType.numBiddingOpportunities:
        return 'Number of Bidding Opportunities';
      case StatType.numPoints:
        return 'Number of Points';
      case StatType.biddingOftenness:
        return 'Bidding Oftenness';
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
      case StatType.winnerRating:
        return 'Winner Rating';
      case StatType.setterRating:
        return 'Setter Rating';
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

  factory OverallRatingStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam,
      {bool isAdjusted = false}) {
    return OverallRatingStatItem(calculateOverallRating(rawStats, isTeam, isAdjusted: isAdjusted));
  }

  static double calculateOverallRating(List<EntityRawGameStats> rawStats, bool isTeam, {bool isAdjusted = false}) {
    double bidderRating = BidderRatingStatItem.calculateBidderRating(rawStats, isTeam, isAdjusted: isAdjusted);
    double winnerRating = WinnerRatingStatItem.calculateWinnerRating(rawStats, isTeam, isAdjusted: isAdjusted);
    double setterRating = SetterRatingStatItem.calculateSetterRating(rawStats, isTeam, isAdjusted: isAdjusted);
    double ovr = bidderRating * 0.45 + winnerRating * 0.45 + setterRating * 0.1;
    return ovr;
  }
}

class BidderRatingStatItem extends RatingStatItem {
  static const MIN_NUM_OPPORTUNITIES = 240;
  static const MIDDLE_TEAM_GAINED_PER_OPPORTUNITY = 1.1;
  static const MIDDLE_PLAYER_GAINED_PER_OPPORTUNITY = 0.75;

  String get statName => 'Bidder Rating';

  BidderRatingStatItem(double bidderRating) : super(bidderRating);

  factory BidderRatingStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam, {bool isAdjusted = false}) {
    return BidderRatingStatItem(calculateBidderRating(rawStats, isTeam, isAdjusted: isAdjusted));
  }

  static double calculateBidderRating(List<EntityRawGameStats> rawStats, bool isTeam, {bool isAdjusted = false}) {
    int numOpportunities = EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumBiddingOpportunities);
    double totalGainedAdj = 0;
    if (isAdjusted && numOpportunities < MIN_NUM_OPPORTUNITIES) {
      if (isTeam) {
        totalGainedAdj = (MIN_NUM_OPPORTUNITIES - numOpportunities) * MIDDLE_TEAM_GAINED_PER_OPPORTUNITY;
      } else {
        totalGainedAdj = (MIN_NUM_OPPORTUNITIES - numOpportunities) * MIDDLE_PLAYER_GAINED_PER_OPPORTUNITY;
      }
      numOpportunities = MIN_NUM_OPPORTUNITIES;
    }
    if (numOpportunities == 0) {
      return 0;
    }
    double totalGained = totalGainedAdj;
    totalGained += EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.GainedOnBids);
    double gainedPerOpportunity = totalGained / numOpportunities;
    if (isTeam) {
      return gainedPerOpportunity / (MIDDLE_TEAM_GAINED_PER_OPPORTUNITY * 2) * 100;
    } else {
      return gainedPerOpportunity / (MIDDLE_PLAYER_GAINED_PER_OPPORTUNITY * 2) * 100;
    }
  }
}

class WinnerRatingStatItem extends RatingStatItem {
  static const MIN_NUM_GAMES = 20;

  String get statName => 'Winner Rating';

  WinnerRatingStatItem(double winnerRating) : super(winnerRating);

  factory WinnerRatingStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam, {bool isAdjusted = false}) {
    return WinnerRatingStatItem(calculateWinnerRating(rawStats, isTeam, isAdjusted: isAdjusted));
  }

  static double calculateWinnerRating(List<EntityRawGameStats> rawStats, bool isTeam, {bool isAdjusted = false}) {
    Record record = WinLossRecordStatItem.calculateRecord(rawStats);
    double wins = record.wins.toDouble();
    double losses = record.losses.toDouble();
    if (isAdjusted) {
      double extra = wins + losses >= MIN_NUM_GAMES ? 0 : MIN_NUM_GAMES - (wins + losses);
      wins += extra / 2;
      losses += extra / 2;
    }
    double total = wins + losses;
    double winningPct = total == 0 ? 0 : wins / (wins + losses) * 100;
    return winningPct;
  }
}

class SetterRatingStatItem extends RatingStatItem {
  static const MIN_NUM_O_BIDS = 120;
  static const MIDDLE_GAINED_BY_SET_PER_O_BID = 1.7;

  String get statName => 'Setter Rating';

  SetterRatingStatItem(double setterRating) : super(setterRating);

  factory SetterRatingStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam, {bool isAdjusted = false}) {
    return SetterRatingStatItem(calculateSetterRating(rawStats, isTeam, isAdjusted: isAdjusted));
  }

  static double calculateSetterRating(List<EntityRawGameStats> rawStats, bool isTeam, {bool isAdjusted = false}) {
    int numOBids = EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumOBids);
    double totalSetterAdj = 0;
    if (isAdjusted && numOBids < MIN_NUM_O_BIDS) {
      totalSetterAdj = (MIN_NUM_O_BIDS - numOBids) * MIDDLE_GAINED_BY_SET_PER_O_BID;
      numOBids = MIN_NUM_O_BIDS;
    }
    if (numOBids == 0) {
      return 0;
    }
    double totalGainedBySetting = totalSetterAdj;
    totalGainedBySetting += EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.GainedBySet);
    double setGainPerOBid = totalGainedBySetting / numOBids;
    return setGainPerOBid / (MIDDLE_GAINED_BY_SET_PER_O_BID * 2) * 100;
  }
}

abstract class PercentageStatItem extends DoubleStatItem {
  PercentageStatItem(double percentage) : super(percentage);

  double get percentage => _value;

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

class BiddingOftennessStatItem extends PercentageStatItem {
  String get statName => 'Bidding Oftenness';

  BiddingOftennessStatItem(double biddingOftenness) : super(biddingOftenness);

  factory BiddingOftennessStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    int numBids = EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumBids);
    int numBiddingOpportunities =
        EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumBiddingOpportunities);
    double biddingOftenness = 0;
    if (numBiddingOpportunities != 0) {
      biddingOftenness = numBids / numBiddingOpportunities;
    }
    return BiddingOftennessStatItem(biddingOftenness);
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
    int wins = 0;
    int losses = 0;
    for (EntityRawGameStats gameStats in rawStats) {
      if (gameStats.isFinished && gameStats.fractionOfGame >= 0.5) {
        if (gameStats.won) {
          wins++;
        } else {
          losses++;
        }
      }
    }
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

class NumBiddingOpportunitiesStatItem extends IntStatItem {
  String get statName => 'Number of Bidding Opportunities';

  NumBiddingOpportunitiesStatItem(int numOpps) : super(numOpps);

  factory NumBiddingOpportunitiesStatItem.fromRawStats(List<EntityRawGameStats> rawStats, bool isTeam) {
    return NumBiddingOpportunitiesStatItem(
        EntityRawGameStats.combineRawStats(rawStats, CombinableRawStat.NumBiddingOpportunities));
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
