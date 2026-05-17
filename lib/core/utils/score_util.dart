class ScoreUtil {
  static Map<String, int> calculateRoundScores({
    required Map<String, int> remainCards,
    required bool spring,
    required int bombCount,
    int singleCardScore = 0,
  }) {
    String? winnerId;
    for (final entry in remainCards.entries) {
      if (entry.value == 0) {
        if (winnerId != null) throw ArgumentError('只能有一人剩余0张牌（赢家）');
        winnerId = entry.key;
      }
    }
    if (winnerId == null) throw ArgumentError('必须有一人剩余0张牌（赢家）');

    int adjustedCards(int cards) => cards == 1 ? singleCardScore : cards;

    final totalRemaining = remainCards.entries
        .where((e) => e.key != winnerId)
        .fold<int>(0, (sum, e) => sum + adjustedCards(e.value));

    final scores = <String, int>{};
    for (final entry in remainCards.entries) {
      if (entry.key == winnerId) {
        int winnerScore = totalRemaining;
        if (spring) winnerScore *= 2;
        scores[entry.key] = winnerScore;
      } else {
        int loserPenalty = adjustedCards(entry.value) + bombCount * 10;
        if (spring) loserPenalty *= 2;
        scores[entry.key] = -loserPenalty;
      }
    }
    return scores;
  }
}
