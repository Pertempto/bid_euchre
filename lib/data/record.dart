class Record {
  int _wins, _losses;

  int get wins => _wins;

  int get losses => _losses;

  Record(this._wins, this._losses);

  int get totalGames {
    return wins + losses;
  }

  double get winningPercentage {
    return wins / totalGames;
  }

  List<int> get asList {
    return [wins, losses];
  }

  @override
  String toString() {
    return '$wins-$losses';
  }
}
