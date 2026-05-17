import 'player.dart';
import 'round.dart';

class Game {
  final String id;
  final List<Player> players;
  final List<RoundModel> rounds;
  final DateTime createdAt;
  final int singleCardScore;
  final bool defaultSpring;
  final bool defaultBomb;

  Game({
    required this.id,
    required this.players,
    this.rounds = const [],
    DateTime? createdAt,
    this.singleCardScore = 0,
    this.defaultSpring = true,
    this.defaultBomb = true,
  }) : createdAt = createdAt ?? DateTime.now();

  Game copyWith({
    List<Player>? players,
    List<RoundModel>? rounds,
    int? singleCardScore,
    bool? defaultSpring,
    bool? defaultBomb,
  }) =>
      Game(
        id: id,
        players: players ?? this.players,
        rounds: rounds ?? this.rounds,
        createdAt: createdAt,
        singleCardScore: singleCardScore ?? this.singleCardScore,
        defaultSpring: defaultSpring ?? this.defaultSpring,
        defaultBomb: defaultBomb ?? this.defaultBomb,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'players': players.map((p) => p.toJson()).toList(),
        'rounds': rounds.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'singleCardScore': singleCardScore,
        'defaultSpring': defaultSpring,
        'defaultBomb': defaultBomb,
      };

  factory Game.fromJson(Map<String, dynamic> json) => Game(
        id: json['id'] as String,
        players: (json['players'] as List<dynamic>?)
                ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        rounds: (json['rounds'] as List<dynamic>?)
                ?.map((r) => RoundModel.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        singleCardScore: (json['singleCardScore'] as num?)?.toInt() ?? 0,
        defaultSpring: json['defaultSpring'] as bool? ?? true,
        defaultBomb: json['defaultBomb'] as bool? ?? true,
      );

  /// Total score per player across all rounds
  Map<String, int> get scoreboard {
    final scores = <String, int>{};
    for (final p in players) {
      scores[p.id] = 0;
    }
    for (final round in rounds) {
      for (final entry in round.scoreDeltas.entries) {
        scores[entry.key] = (scores[entry.key] ?? 0) + entry.value;
      }
    }
    return scores;
  }

  /// Win count per player
  Map<String, int> get winCounts {
    final wins = <String, int>{};
    for (final p in players) {
      wins[p.id] = 0;
    }
    for (final round in rounds) {
      wins[round.winnerId] = (wins[round.winnerId] ?? 0) + 1;
    }
    return wins;
  }

  /// Stats for the current game
  Map<String, int> get stats {
    int totalBombs = 0;
    int springCount = 0;
    int totalRemainCards = 0;
    for (final r in rounds) {
      totalBombs += r.bombCount;
      if (r.spring) { springCount++; }
      totalRemainCards += r.remainCards.values.fold(0, (a, b) => a + b);
    }
    return {
      'totalBombs': totalBombs,
      'springCount': springCount,
      'totalRemainCards': totalRemainCards,
    };
  }

  /// Consecutive wins for a player (looking from latest round backwards)
  int winStreakFor(String playerId) {
    int streak = 0;
    for (final r in rounds.reversed) {
      if (r.winnerId == playerId) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
