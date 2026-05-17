import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/game.dart';

class HiveService {
  static const _gamesBoxName = 'games';
  static const _namesBoxName = 'player_names';
  static const _settingsBoxName = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_gamesBoxName);
    await Hive.openBox<String>(_namesBoxName);
    await Hive.openBox<String>(_settingsBoxName);
  }

  Box<String> get _gamesBox => Hive.box<String>(_gamesBoxName);
  Box<String> get _namesBox => Hive.box<String>(_namesBoxName);
  Box<String> get _settingsBox => Hive.box<String>(_settingsBoxName);

  List<Game> getAllGames() {
    return _gamesBox.values.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return Game.fromJson(map);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Game? getGame(String id) {
    final json = _gamesBox.get(id);
    if (json == null) return null;
    return Game.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> saveGame(Game game) async {
    await _gamesBox.put(game.id, jsonEncode(game.toJson()));
  }

  Future<void> deleteGame(String id) async {
    await _gamesBox.delete(id);
  }

  List<String> getRecentNames() {
    final json = _namesBox.get('names');
    if (json == null) return [];
    return (jsonDecode(json) as List<dynamic>).cast<String>();
  }

  Future<void> saveRecentNames(List<String> names) async {
    final unique = names.toSet().toList();
    if (unique.length > 20) { unique.removeRange(20, unique.length); }
    await _namesBox.put('names', jsonEncode(unique));
  }

  int getLastPlayerCount() {
    final val = _settingsBox.get('lastPlayerCount');
    return val != null ? int.tryParse(val) ?? 3 : 3;
  }

  Future<void> saveLastPlayerCount(int count) async {
    await _settingsBox.put('lastPlayerCount', count.toString());
  }

  bool getEnableSpring() {
    final val = _settingsBox.get('enableSpring');
    return val != null ? val == 'true' : true;
  }

  Future<void> saveEnableSpring(bool v) async {
    await _settingsBox.put('enableSpring', v.toString());
  }

  bool getEnableBomb() {
    final val = _settingsBox.get('enableBomb');
    return val != null ? val == 'true' : true;
  }

  Future<void> saveEnableBomb(bool v) async {
    await _settingsBox.put('enableBomb', v.toString());
  }

  int getSingleCardScore() {
    final val = _settingsBox.get('singleCardScore');
    return val != null ? int.tryParse(val) ?? 0 : 0;
  }

  Future<void> saveSingleCardScore(int v) async {
    await _settingsBox.put('singleCardScore', v.toString());
  }
}
