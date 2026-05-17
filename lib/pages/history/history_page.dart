import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/player.dart';
import '../../models/game.dart';
import '../../providers/game_provider.dart';
import '../../routes/app_routes.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryPage extends StatefulWidget {
  final bool showStats;
  const HistoryPage({super.key, this.showStats = false});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late bool _showStats;

  @override
  void initState() {
    super.initState();
    _showStats = widget.showStats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史 & 统计'),
        actions: [
          IconButton(
            icon: Icon(_showStats ? Icons.list : Icons.bar_chart, color: AppColors.textSecondary),
            onPressed: () => setState(() => _showStats = !_showStats),
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, _) {
          final games = provider.allGames;
          if (games.isEmpty) {
            return const Center(
              child: Text('暂无记录', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            );
          }
          if (_showStats) return _statsView(games);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            itemBuilder: (_, i) => _gameCard(games[i], provider, context),
          );
        },
      ),
    );
  }

  Widget _gameCard(Game game, GameProvider provider, BuildContext context) {
    final scoreboard = game.scoreboard;
    final winCounts = game.winCounts;
    final sorted = List<Player>.from(game.players)
      ..sort((a, b) => (scoreboard[b.id] ?? 0).compareTo(scoreboard[a.id] ?? 0));

    return GestureDetector(
      onTap: () {
        provider.setCurrentGame(game);
        Navigator.pushNamed(context, AppRoutes.result);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${game.players.length}人局 · ${game.rounds.length}局',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    provider.setCurrentGame(game);
                    Navigator.pushNamed(context, AppRoutes.game);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('编辑', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            ...sorted.take(3).toList().asMap().entries.map((e) {
              final rank = e.key;
              final p = e.value;
              final score = scoreboard[p.id] ?? 0;
              final won = winCounts[p.id] ?? 0;
              final isPos = score >= 0;
              return Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    Text(['🥇', '🥈', '🥉'][rank], style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Expanded(child: Text('${p.name} ($won胜)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                    Text(
                      '${isPos ? '+' : ''}$score',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isPos ? AppColors.positiveScore : AppColors.negativeScore),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _statsView(List<Game> games) {
    final stats = <String, Map<String, dynamic>>{};
    var totalRounds = 0;
    for (final g in games) {
      totalRounds += g.rounds.length;
      final sb = g.scoreboard;
      final wc = g.winCounts;
      for (final p in g.players) {
        stats.putIfAbsent(p.id, () => {'name': p.name, 'totalScore': 0, 'games': 0, 'won': 0, 'played': 0});
        stats[p.id]!['totalScore'] = (stats[p.id]!['totalScore'] as int) + (sb[p.id] ?? 0);
        stats[p.id]!['games'] = (stats[p.id]!['games'] as int) + 1;
        stats[p.id]!['won'] = (stats[p.id]!['won'] as int) + (wc[p.id] ?? 0);
        stats[p.id]!['played'] = (stats[p.id]!['played'] as int) + g.rounds.length;
      }
    }
    final players = stats.entries.toList()
      ..sort((a, b) => (b.value['totalScore'] as int).compareTo(a.value['totalScore'] as int));

    final bars = players.take(6).map((p) {
      final s = p.value['totalScore'] as int;
      return BarChartGroupData(
        x: players.indexOf(p),
        barRods: [BarChartRodData(toY: s.toDouble(), color: s >= 0 ? AppColors.positiveScore : AppColors.negativeScore, width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))],
      );
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _statBox('${games.length}', '总牌局', AppColors.primary),
            const SizedBox(width: 10),
            _statBox('$totalRounds', '总局数', AppColors.success),
            const SizedBox(width: 10),
            _statBox('${stats.length}', '总玩家', AppColors.warning),
          ],
        ),
        if (bars.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('积分榜', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: bars,
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.cardBorder, strokeWidth: 0.5)),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i >= players.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(players[i].value['name'] as String, style: const TextStyle(fontSize: 10, color: AppColors.textHint), overflow: TextOverflow.ellipsis),
                        );
                      },
                      reservedSize: 20,
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(color: AppColors.textHint, fontSize: 10)))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        const Text('排行', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...players.map((p) {
          final name = p.value['name'] as String;
          final score = p.value['totalScore'] as int;
          final gm = p.value['games'] as int;
          final won = p.value['won'] as int;
          final played = p.value['played'] as int;
          final wr = played > 0 ? (won / played * 100).toStringAsFixed(0) : '0';
          final isPos = score >= 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder, width: 0.5)),
            child: Row(
              children: [
                SizedBox(width: 24, child: Text('${players.indexOf(p) + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHint))),
                Expanded(child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                Text('$gm局 $wr%', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                const SizedBox(width: 12),
                Text('${isPos ? '+' : ''}$score', style: TextStyle(fontWeight: FontWeight.bold, color: isPos ? AppColors.positiveScore : AppColors.negativeScore)),
              ],
            ),
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _statBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder, width: 0.5)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
