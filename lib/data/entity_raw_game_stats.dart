class EntityRawGameStats {
  String entityId;
  bool isFinished;
  bool isArchived;
  bool isFullGame;
  bool won;
  int timestamp;
  int numRounds;
  int numPoints;
  int numBids;
  int madeBids;
  int biddingTotal;
  int gainedOnBids;
  int supportedGain;

  EntityRawGameStats(this.entityId) {
    this.numRounds = 0;
    this.numPoints = 0;
    this.numBids = 0;
    this.madeBids = 0;
    this.biddingTotal = 0;
    this.gainedOnBids = 0;
    this.supportedGain = 0;
  }

  static int combineRawStats(List<EntityRawGameStats> rawStats, CombinableRawStat rawStat) {
    int total = 0;
    for (EntityRawGameStats gameRawStats in rawStats) {
      switch (rawStat) {
        case CombinableRawStat.NumGames:
          total++;
          break;
        case CombinableRawStat.NumRounds:
          total += gameRawStats.numRounds;
          break;
        case CombinableRawStat.NumPoints:
          total += gameRawStats.numPoints;
          break;
        case CombinableRawStat.NumBids:
          total += gameRawStats.numBids;
          break;
        case CombinableRawStat.MadeBids:
          total += gameRawStats.madeBids;
          break;
        case CombinableRawStat.BiddingTotal:
          total += gameRawStats.biddingTotal;
          break;
        case CombinableRawStat.GainedOnBids:
          total += gameRawStats.gainedOnBids;
          break;
        case CombinableRawStat.SupportedGain:
          total += gameRawStats.supportedGain;
          break;
      }
    }
    return total;
  }
}

enum CombinableRawStat { NumGames, NumRounds, NumPoints, NumBids, MadeBids, BiddingTotal, GainedOnBids, SupportedGain }
