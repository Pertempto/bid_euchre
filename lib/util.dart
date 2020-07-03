class Util {
  static String scoreString(int score) {
    return score < 0 ? '($score)' : '$score';
  }
}
