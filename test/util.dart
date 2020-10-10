import 'dart:math';

String randomId() {
  List<String> choices = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".split("");
  return List.generate(28, (index) => randomChoice(choices)).join();
}

int randomPlayerIndex() {
  return Random().nextInt(4);
}

int randomBid() {
  return randomChoice([3, 4, 5, 6, 12, 24]);
}

dynamic randomChoice(List choices) {
  Random rand = Random();
  return choices[rand.nextInt(choices.length)];
}
