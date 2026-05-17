import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_util.dart';
import '../../models/player.dart';
import '../../models/game.dart';
import '../../providers/game_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/hive_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _entranceAnim;
  late AnimationController _breatheAnim;
  late Animation<double> _breatheScale;
  final _hive = HiveService();
  late bool _enableSpring;
  late bool _enableBomb;
  late int _singleCardScore;

  @override
  void initState() {
    super.initState();
    _entranceAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _breatheAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _breatheScale = Tween<double>(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _breatheAnim, curve: Curves.easeInOut));
    _entranceAnim.forward();
    _breatheAnim.repeat(reverse: true);
    _enableSpring = _hive.getEnableSpring();
    _enableBomb = _hive.getEnableBomb();
    _singleCardScore = _hive.getSingleCardScore();
  }

  @override
  void dispose() {
    _entranceAnim.dispose();
    _breatheAnim.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) { return '上午好'; }
    if (h < 18) { return '下午好'; }
    return '晚上好';
  }

  int _todayRounds(List<Game> games) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return games.where((g) => g.createdAt.isAfter(today)).fold(0, (sum, g) => sum + g.rounds.length);
  }

  String _todayTopPlayer(List<Game> games) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scores = <String, int>{};
    for (final g in games.where((g) => g.createdAt.isAfter(today))) {
      for (final e in g.scoreboard.entries) {
        scores[e.key] = (scores[e.key] ?? 0) + e.value;
      }
    }
    if (scores.isEmpty) return '';
    final top = scores.entries.reduce((a, b) => a.value > b.value ? a : b);
    // Find player name across games
    for (final g in games) {
      for (final p in g.players) {
        if (p.id == top.key) return '${p.name} +${top.value}';
      }
    }
    return '';
  }

  Game? _unfinishedGame(List<Game> games) {
    if (games.isEmpty) { return null; }
    final latest = games.first;
    return latest.rounds.isEmpty ? latest : null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final games = provider.allGames;
    final todayRounds = _todayRounds(games);
    final topPlayer = _todayTopPlayer(games);
    final unfinished = _unfinishedGame(games);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          children: [
            _buildBrand(todayRounds, topPlayer),
            const SizedBox(height: 32),
            _buildStartButton(unfinished, provider),
            const SizedBox(height: 32),
            _buildQuickGrid(),
            const SizedBox(height: 24),
            _buildRulesCard(),
            if (games.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildRecentGames(games, provider),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Brand Area ───────────────────────────────────────

  Widget _buildBrand(int todayRounds, String topPlayer) {
    final fadeSlide = CurvedAnimation(parent: _entranceAnim, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));

    return AnimatedBuilder(
      animation: fadeSlide,
      builder: (_, child) => Opacity(
        opacity: fadeSlide.value,
        child: Transform.translate(
          offset: Offset(0, -20 * (1 - fadeSlide.value)),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_greeting()} 👋', style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('跑得快记分', style: TextStyle(color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(
            todayRounds > 0 ? '今晚已经进行了 $todayRounds 局' : '等待第一局开始',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          if (topPlayer.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('🏆 ', style: TextStyle(fontSize: 13)),
                Text(
                  '今日最佳 $topPlayer',
                  style: const TextStyle(color: AppColors.positiveScore, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Start Button ─────────────────────────────────────

  Widget _buildStartButton(Game? unfinished, GameProvider provider) {
    final btnFade = CurvedAnimation(parent: _entranceAnim, curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic));

    return AnimatedBuilder(
      animation: btnFade,
      builder: (_, child) => Opacity(
        opacity: btnFade.value,
        child: Transform.scale(
          scale: 0.9 + 0.1 * btnFade.value,
          child: child,
        ),
      ),
      child: AnimatedBuilder(
        animation: _breatheScale,
        builder: (_, child) => Transform.scale(scale: _breatheScale.value, child: child),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (unfinished != null) {
              provider.setCurrentGame(unfinished);
              Navigator.pushNamed(context, AppRoutes.game);
            } else {
              Navigator.pushNamed(context, AppRoutes.createGame);
            }
          },
          child: Container(
            width: double.infinity,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.positiveScore, Color(0xFF16A34A)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppColors.positiveScore.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Center(
              child: unfinished != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('继续当前牌局', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 2)),
                        const SizedBox(height: 2),
                        Text(
                          '${unfinished.players.length}人局 · ${unfinished.players.map((p) => p.name).join('、')}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('▶ ', style: TextStyle(color: Colors.white, fontSize: 18)),
                        Text('开始新牌局', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 2)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Quick Grid ───────────────────────────────────────

  Widget _buildQuickGrid() {
    final gridFade = CurvedAnimation(parent: _entranceAnim, curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic));

    final items = [
      {'icon': '🕘', 'title': '牌局记录', 'route': AppRoutes.history, 'args': false},
      {'icon': '📈', 'title': '数据统计', 'route': AppRoutes.history, 'args': true},
      {'icon': '🏆', 'title': '排行榜', 'route': AppRoutes.history, 'args': true},
    ];

    return AnimatedBuilder(
      animation: gridFade,
      builder: (_, child) => Opacity(
        opacity: gridFade.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - gridFade.value)),
          child: child,
        ),
      ),
      child: Row(
        children: items.asMap().entries.map((e) {
          return Expanded(
            child: _gridCard(e.value, e.key, gridFade),
          );
        }).toList(),
      ),
    );
  }

  Widget _gridCard(Map<String, Object> item, int index, Animation<double> parentAnim) {
    final staggered = CurvedAnimation(parent: _entranceAnim, curve: Interval((0.3 + index * 0.08).clamp(0.0, 1.0), (0.7 + index * 0.08).clamp(0.0, 1.0), curve: Curves.easeOutCubic));

    return AnimatedBuilder(
      animation: staggered,
      builder: (_, child) => Opacity(
        opacity: staggered.value,
        child: Transform.translate(offset: Offset(0, 30 * (1 - staggered.value)), child: child),
      ),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, item['route'] as String, arguments: item['args']),
        child: Container(
          margin: EdgeInsets.only(left: index.isOdd ? 5 : 0, right: index.isOdd ? 0 : 5),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Column(
            children: [
              Text(item['icon'] as String, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(item['title'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Rules Card ───────────────────────────────────────

  Widget _buildRulesCard() {
    final rulesFade = CurvedAnimation(parent: _entranceAnim, curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic));

    return AnimatedBuilder(
      animation: rulesFade,
      builder: (_, child) => Opacity(
        opacity: rulesFade.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - rulesFade.value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
        ),
        child: Column(
          children: [
            // Spring
            Row(
              children: [
                const Text('春天翻倍', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => _enableSpring = !_enableSpring);
                    _hive.saveEnableSpring(_enableSpring);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: _enableSpring ? AppColors.positiveScore : AppColors.surfaceLight,
                    ),
                    alignment: _enableSpring ? Alignment.centerRight : Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Bomb
            Row(
              children: [
                const Text('炸弹加分', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => _enableBomb = !_enableBomb);
                    _hive.saveEnableBomb(_enableBomb);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: _enableBomb ? AppColors.positiveScore : AppColors.surfaceLight,
                    ),
                    alignment: _enableBomb ? Alignment.centerRight : Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Single Card Score
            Row(
              children: [
                const Text('独牌积分', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                _smallBtn(Icons.remove, () {
                  if (_singleCardScore > 0) {
                    setState(() => _singleCardScore--);
                    _hive.saveSingleCardScore(_singleCardScore);
                  }
                }),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  child: Text(
                    '$_singleCardScore',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _singleCardScore == 0 ? AppColors.positiveScore : AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _smallBtn(Icons.add, () {
                  setState(() => _singleCardScore++);
                  _hive.saveSingleCardScore(_singleCardScore);
                }),
              ],
            ),
            const SizedBox(height: 4),
            const Text('剩余1张牌时的计分，0=不计', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _smallBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 16),
      ),
    );
  }

  // ─── Recent Games ─────────────────────────────────────

  Widget _buildRecentGames(List<Game> games, GameProvider provider) {
    final listFade = CurvedAnimation(parent: _entranceAnim, curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic));
    final displayGames = games.take(5).toList();

    return AnimatedBuilder(
      animation: listFade,
      builder: (_, child) => Opacity(
        opacity: listFade.value,
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('最近牌局', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          ...displayGames.asMap().entries.map((e) {
            final i = e.key;
            final game = e.value;
            final scoreboard = game.scoreboard;
            final sorted = List<Player>.from(game.players)
              ..sort((a, b) => (scoreboard[b.id] ?? 0).compareTo(scoreboard[a.id] ?? 0));
            final winner = sorted.isNotEmpty ? sorted.first : null;
            final winnerScore = winner != null ? (scoreboard[winner.id] ?? 0) : 0;
            final winnerIdx = winner != null ? game.players.indexWhere((p) => p.id == winner.id) : 0;
            final barColor = AppColors.playerColors[winnerIdx % AppColors.playerColors.length];

            // Staggered entrance
            final staggered = CurvedAnimation(
              parent: _entranceAnim,
              curve: Interval((0.5 + i * 0.08).clamp(0.0, 1.0), (0.9 + i * 0.08).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
            );

            return AnimatedBuilder(
              animation: staggered,
              builder: (_, child) => Opacity(
                opacity: staggered.value,
                child: Transform.translate(offset: Offset(0, 40 * (1 - staggered.value)), child: child),
              ),
              child: GestureDetector(
                onTap: () {
                  provider.setCurrentGame(game);
                  Navigator.pushNamed(context, game.rounds.isEmpty ? AppRoutes.game : AppRoutes.result);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Container(width: 3, height: 84, color: barColor),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${game.players.length}人局 · ${game.rounds.length}局',
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateUtil.relativeDate(game.createdAt),
                                      style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                                    ),
                                    const SizedBox(height: 6),
                                    if (winner != null)
                                      Row(
                                        children: [
                                          const Text('🏆', style: TextStyle(fontSize: 13)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${winner.name} +$winnerScore',
                                            style: const TextStyle(color: AppColors.positiveScore, fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
