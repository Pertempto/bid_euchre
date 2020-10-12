class Record {
  int _wins, _losses;

  int get wins => _wins;

  int get losses => _losses;

  Record(this._wins, this._losses);

  int get total {
    return wins + losses;
  }

  double get winningPercentage {
    if (total == 0) {
      return 0;
    }
    return wins / total;
  }

  List<int> get asList {
    return [wins, losses];
  }

  @override
  String toString() {
    return '$wins-$losses';
  }

  addWin() {
    _wins++;
  }

  addLoss() {
    _losses++;
  }
}
