import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../models/round.dart';
import '../services/hive_service.dart';
import '../services/game_service.dart';

class GameProvider extends ChangeNotifier {
  final HiveService _hive = HiveService();
  late final GameService _gameService;

  List<Game> _allGames = [];
  Game? _currentGame;

  GameProvider() {
    _gameService = GameService(_hive);
    _allGames = _hive.getAllGames();
  }

  List<Game> get allGames => _allGames;
  Game? get currentGame => _currentGame;

  void setCurrentGame(Game game) {
    _currentGame = game;
    notifyListeners();
  }

  void createGame({
    required List<Player> players,
    int singleCardScore = 0,
    bool enableSpring = true,
    bool enableBomb = true,
  }) {
    final game = _gameService.createGame(
      players: players,
      singleCardScore: singleCardScore,
      defaultSpring: enableSpring,
      defaultBomb: enableBomb,
    );
    _hive.saveGame(game);
    _currentGame = game;
    _allGames = _hive.getAllGames();
    notifyListeners();
  }

  void submitRound({
    required String winnerId,
    required Map<String, int> remainCards,
    bool spring = false,
    int bombCount = 0,
    int singleCardScore = 0,
  }) {
    if (_currentGame == null) return;
    final round = _gameService.submitRound(
      game: _currentGame!,
      winnerId: winnerId,
      remainCards: remainCards,
      spring: spring,
      bombCount: bombCount,
      singleCardScore: singleCardScore,
    );
    _currentGame = _currentGame!.copyWith(
      rounds: [..._currentGame!.rounds, round],
    );
    _allGames = _hive.getAllGames();
    notifyListeners();
  }

  void replaceRound(int index, {
    required String winnerId,
    required Map<String, int> remainCards,
    bool spring = false,
    int bombCount = 0,
    int singleCardScore = 0,
  }) {
    if (_currentGame == null || index < 0 || index >= _currentGame!.rounds.length) return;
    final round = RoundModel(
      winnerId: winnerId,
      remainCards: remainCards,
      spring: spring,
      bombCount: bombCount,
      singleCardScore: singleCardScore,
    );
    final newRounds = List<RoundModel>.from(_currentGame!.rounds);
    newRounds[index] = round;
    _currentGame = _currentGame!.copyWith(rounds: newRounds);
    _hive.saveGame(_currentGame!);
    _allGames = _hive.getAllGames();
    notifyListeners();
  }

  void undoLastRound() {
    if (_currentGame == null || _currentGame!.rounds.isEmpty) return;
    final updatedGame = _currentGame!.copyWith(
      rounds: List<RoundModel>.from(_currentGame!.rounds)..removeLast(),
    );
    _currentGame = updatedGame;
    _hive.saveGame(_currentGame!);
    _allGames = _hive.getAllGames();
    notifyListeners();
  }

  Future<void> saveGame() async {
    if (_currentGame == null) return;
    await _gameService.saveGame(_currentGame!);
    _allGames = _hive.getAllGames();
    notifyListeners();
  }

  void deleteGame(String id) {
    _gameService.deleteGame(id);
    _allGames = _hive.getAllGames();
    if (_currentGame?.id == id) {
      _currentGame = null;
    }
    notifyListeners();
  }

  void refresh() {
    _allGames = _hive.getAllGames();
    if (_currentGame != null) {
      _currentGame = _hive.getGame(_currentGame!.id);
    }
    notifyListeners();
  }
}
