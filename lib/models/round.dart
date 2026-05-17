import '../core/utils/score_util.dart';

class RoundModel {
  final String winnerId;
  final Map<String, int> remainCards;
  final bool spring;
  final int bombCount;
  final int singleCardScore;

  RoundModel({
    required this.winnerId,
    required this.remainCards,
    this.spring = false,
    this.bombCount = 0,
    this.singleCardScore = 0,
  });

  Map<String, int> get scoreDeltas {
    return ScoreUtil.calculateRoundScores(
      remainCards: remainCards,
      spring: spring,
      bombCount: bombCount,
      singleCardScore: singleCardScore,
    );
  }

  Map<String, dynamic> toJson() => {
        'winnerId': winnerId,
        'remainCards': remainCards,
        'spring': spring,
        'bombCount': bombCount,
        'singleCardScore': singleCardScore,
      };

  factory RoundModel.fromJson(Map<String, dynamic> json) => RoundModel(
        winnerId: json['winnerId'] as String,
        remainCards: Map<String, int>.from(
          (json['remainCards'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
        ),
        spring: json['spring'] as bool? ?? false,
        bombCount: (json['bombCount'] as num?)?.toInt() ?? 0,
        singleCardScore: (json['singleCardScore'] as num?)?.toInt() ?? 0,
      );
}
