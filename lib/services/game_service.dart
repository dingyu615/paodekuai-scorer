import 'package:uuid/uuid.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../models/round.dart';
import 'hive_service.dart';

class GameService {
  final HiveService _hive;
  final _uuid = const Uuid();

  GameService(this._hive);

  Game createGame({
    required List<Player> players,
    int singleCardScore = 0,
    bool defaultSpring = true,
    bool defaultBomb = true,
  }) {
    return Game(
      id: _uuid.v4(),
      players: players,
      singleCardScore: singleCardScore,
      defaultSpring: defaultSpring,
      defaultBomb: defaultBomb,
    );
  }

  RoundModel submitRound({
    required Game game,
    required String winnerId,
    required Map<String, int> remainCards,
    bool spring = false,
    int bombCount = 0,
    int singleCardScore = 0,
  }) {
    final round = RoundModel(
      winnerId: winnerId,
      remainCards: remainCards,
      spring: spring,
      bombCount: bombCount,
      singleCardScore: singleCardScore,
    );

    final updatedGame = game.copyWith(rounds: [...game.rounds, round]);
    _hive.saveGame(updatedGame);
    return round;
  }

  Future<void> saveGame(Game game) async {
    await _hive.saveGame(game);
  }

  Future<void> deleteGame(String id) async {
    await _hive.deleteGame(id);
  }
}
