import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/player.dart';
import '../../models/game.dart';
import '../../providers/game_provider.dart';
import '../../routes/app_routes.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _headerFade;
  late Animation<double> _headerScale;
  late Animation<double> _listSlide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _headerFade = CurvedAnimation(parent: _anim, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
    _headerScale = CurvedAnimation(parent: _anim, curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic));
    _listSlide = CurvedAnimation(parent: _anim, curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final game = provider.currentGame;
    if (game == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('结果')),
        body: const Center(child: Text('数据不存在', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    final scoreboard = game.scoreboard;
    final winCounts = game.winCounts;
    final sorted = List<Player>.from(game.players)
      ..sort((a, b) => (scoreboard[b.id] ?? 0).compareTo(scoreboard[a.id] ?? 0));
    final winner = sorted.first;
    final winnerScore = scoreboard[winner.id] ?? 0;

    // Compute last round delta for winner
    int lastRoundDelta = 0;
    if (game.rounds.isNotEmpty) {
      final lastRound = game.rounds.last;
      lastRoundDelta = lastRound.scoreDeltas[winner.id] ?? 0;
    }

    final streak = game.winStreakFor(winner.id);
    final stats = game.stats;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(winner, lastRoundDelta, winnerScore, streak),
                _buildRankings(sorted, game, winCounts),
                _buildStats(stats, game),
                const SizedBox(height: 120),
              ],
            ),
          ),
          _buildActions(game, provider),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────

  Widget _buildHeader(Player winner, int roundDelta, int totalScore, int streak) {
    return FadeTransition(
      opacity: _headerFade,
      child: ScaleTransition(
        scale: _headerScale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F172A), Color(0xFF020617)],
            ),
          ),
          child: SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                const Text('本局结束', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
                const SizedBox(height: 12),
                Text(
                  '${winner.name} 获胜',
                  style: const TextStyle(
                    color: Color(0xFFFACC15),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Color(0x40FACC15), blurRadius: 20)],
                  ),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: roundDelta.toDouble()),
                  duration: const Duration(milliseconds: 600),
                  builder: (_, val, __) => Text(
                    '+${val.toInt()}',
                    style: const TextStyle(color: AppColors.positiveScore, fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Text('总积分: ${totalScore >= 0 ? "+" : ""}$totalScore',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                if (streak >= 2) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('🔥 $streak连胜', style: const TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Rankings ─────────────────────────────────────────

  Widget _buildRankings(List<Player> sorted, Game game, Map<String, int> winCounts) {
    final scoreboard = game.scoreboard;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('当前总排名', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...sorted.asMap().entries.map((e) {
            final rank = e.key;
            final p = e.value;
            final score = scoreboard[p.id] ?? 0;
            final won = winCounts[p.id] ?? 0;
            final isPos = score >= 0;
            final isFirst = rank == 0;

            // Round delta from last round
            int delta = 0;
            if (game.rounds.isNotEmpty) {
              delta = game.rounds.last.scoreDeltas[p.id] ?? 0;
            }
            final deltaStr = delta >= 0 ? '+$delta' : '$delta';

            return AnimatedBuilder(
              animation: _listSlide,
              builder: (_, child) {
                final staggered = ((_listSlide.value - rank * 0.12).clamp(0.0, 1.0));
                return Opacity(
                  opacity: staggered,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - staggered)),
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isFirst ? AppColors.gold.withValues(alpha: 0.08) : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isFirst ? AppColors.gold.withValues(alpha: 0.35) : AppColors.cardBorder,
                    width: isFirst ? 1.5 : 0.5,
                  ),
                  boxShadow: isFirst
                      ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        ['🥇', '🥈', '🥉'][rank],
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('$won胜 / ${game.rounds.length}局', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isPos ? '+' : ''}$score',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isPos ? AppColors.positiveScore : AppColors.negativeScore),
                        ),
                        Text(
                          '本局 $deltaStr',
                          style: TextStyle(fontSize: 12, color: delta >= 0 ? AppColors.positiveScore : AppColors.negativeScore),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Stats Grid ───────────────────────────────────────

  Widget _buildStats(Map<String, int> stats, Game game) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('本局数据', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _statCard('${stats['totalBombs'] ?? 0}', '炸弹数', AppColors.negativeScore)),
              const SizedBox(width: 10),
              Expanded(child: _statCard('${stats['springCount'] ?? 0}', '春天次数', AppColors.warning)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _statCard('${stats['totalRemainCards'] ?? 0}', '总剩余牌', AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _statCard('${game.rounds.length}', '总局数', AppColors.positiveScore)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────

  Widget _buildActions(Game game, GameProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Primary: 编辑/继续
            GestureDetector(
              onTap: () {
                provider.setCurrentGame(game);
                Navigator.pushReplacementNamed(context, AppRoutes.game);
              },
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.positiveScore,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('编辑 / 继续', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Secondary row: 返回首页
            GestureDetector(
              onTap: () {
                provider.saveGame();
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('返回首页', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Delete (small)
            GestureDetector(
              onTap: () async {
                final nav = Navigator.of(context);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('删除记录', style: TextStyle(color: AppColors.textPrimary)),
                    content: const Text('删除后无法恢复', style: TextStyle(color: AppColors.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: AppColors.textSecondary))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: AppColors.negativeScore))),
                    ],
                  ),
                );
                if (ok == true) {
                  provider.deleteGame(game.id);
                  nav.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: const Center(
                  child: Text('删除此局', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
