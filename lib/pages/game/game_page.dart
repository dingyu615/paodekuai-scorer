import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game.dart';
import '../../models/player.dart';
import '../../models/round.dart';
import '../../providers/game_provider.dart';
import '../../routes/app_routes.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final Map<String, int> _remain = {};
  String? _winnerId;
  bool _spring = false;
  int _bombCount = 0;
  int _singleCardScore = 0;
  int? _editingRoundIndex;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = context.read<GameProvider>().currentGame;
      if (game != null) { _resetForm(game); }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _resetForm(Game game) {
    setState(() {
      _remain.clear();
      _winnerId = null;
      _spring = game.defaultSpring;
      _bombCount = 0;
      _singleCardScore = game.singleCardScore;
      _editingRoundIndex = null;
      for (final p in game.players) {
        _remain[p.id] = 0;
      }
    });
  }

  void _loadRound(RoundModel round, int index) {
    setState(() {
      _editingRoundIndex = index;
      _winnerId = round.winnerId;
      _spring = round.spring;
      _bombCount = round.bombCount;
      _singleCardScore = round.singleCardScore;
      _remain.clear();
      _remain.addAll(round.remainCards);
    });
  }

  void _cancelEdit() {
    final game = context.read<GameProvider>().currentGame;
    if (game != null) { _resetForm(game); }
  }

  void _submit() {
    final provider = context.read<GameProvider>();
    final game = provider.currentGame;
    if (game == null || _winnerId == null) return;

    final zeroPlayers = _remain.entries.where((e) => e.value == 0).toList();
    if (zeroPlayers.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('必须且仅有一人剩余0张牌'), backgroundColor: AppColors.negativeScore),
      );
      return;
    }

    if (_editingRoundIndex != null) {
      provider.replaceRound(
        _editingRoundIndex!,
        winnerId: _winnerId!,
        remainCards: Map.from(_remain),
        spring: _spring,
        bombCount: _bombCount,
        singleCardScore: _singleCardScore,
      );
    } else {
      provider.submitRound(
        winnerId: _winnerId!,
        remainCards: Map.from(_remain),
        spring: _spring,
        bombCount: _bombCount,
        singleCardScore: _singleCardScore,
      );
    }
    _resetForm(game);
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final game = provider.currentGame;
    if (game == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('牌局')),
        body: const Center(child: Text('请先创建游戏', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    final roundNumber = game.rounds.length + 1;
    final scoreboard = game.scoreboard;
    final sorted = List<Player>.from(game.players)
      ..sort((a, b) => (scoreboard[b.id] ?? 0).compareTo(scoreboard[a.id] ?? 0));
    final topScore = sorted.isNotEmpty ? (scoreboard[sorted.first.id] ?? 0) : 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _editingRoundIndex != null ? '编辑第 ${_editingRoundIndex! + 1} 局' : '第 $roundNumber 局',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          if (_editingRoundIndex != null)
            TextButton(
              onPressed: _cancelEdit,
              child: const Text('取消编辑', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 28),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              switch (v) {
                case 'undo':
                  provider.undoLastRound();
                  _resetForm(game);
                  break;
                case 'delete':
                  final nav = Navigator.of(context);
                  showDialog<bool>(
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
                  ).then((ok) {
                    if (ok == true) {
                      provider.deleteGame(game.id);
                      nav.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
                    }
                  });
                  break;
                case 'finish':
                  provider.saveGame();
                  Navigator.pushReplacementNamed(context, AppRoutes.result);
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'undo',
                enabled: game.rounds.isNotEmpty,
                child: Text('撤销上局', style: TextStyle(color: game.rounds.isNotEmpty ? AppColors.textPrimary : AppColors.textHint, fontSize: 14)),
              ),
              const PopupMenuItem(value: 'finish', child: Text('结束牌局', style: TextStyle(color: AppColors.textPrimary, fontSize: 14))),
              const PopupMenuItem(value: 'delete', child: Text('删除本局', style: TextStyle(color: AppColors.negativeScore, fontSize: 14))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _buildScoreCards(sorted, scoreboard, topScore),
                const SizedBox(height: 24),
                _buildWinnerPicker(game.players),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _winnerId != null
                      ? Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildRemainCards(game.players),
                            const SizedBox(height: 16),
                            _buildExtraRules(),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                if (game.rounds.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildRoundHistory(game),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  // ─── Score Cards ───────────────────────────────────────

  Widget _buildScoreCards(List<Player> sorted, Map<String, int> scoreboard, int topScore) {
    return Row(
      children: sorted.map((p) {
        final score = scoreboard[p.id] ?? 0;
        final isPositive = score >= 0;
        final isTop = score == topScore && topScore != 0;
        final idx = sorted.indexOf(p);

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: idx < sorted.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isTop ? AppColors.positiveScore : AppColors.cardBorder,
                width: isTop ? 1.5 : 0.5,
              ),
            ),
            child: Column(
              children: [
                if (isTop)
                  const Text('👑', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 2),
                Text(p.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  '${isPositive ? '+' : ''}$score',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? AppColors.positiveScore : AppColors.negativeScore,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Winner Picker ─────────────────────────────────────

  Widget _buildWinnerPicker(List<Player> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _editingRoundIndex != null ? '修改第 ${_editingRoundIndex! + 1} 局赢家' : '本局赢家',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Row(
          children: players.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            final selected = _winnerId == p.id;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _winnerId = p.id;
                    _remain[p.id] = 0;
                    for (final other in players) {
                      if (other.id != p.id && (_remain[other.id] ?? 0) == 0) {
                        _remain[other.id] = 1;
                      }
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: i < players.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.positiveScore : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppColors.positiveScore : AppColors.cardBorder,
                      width: selected ? 2 : 0.5,
                    ),
                  ),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textSecondary,
                      ),
                      child: Text(p.name),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Remain Cards ──────────────────────────────────────

  Widget _buildRemainCards(List<Player> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('剩余牌数', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...players.map((p) {
          final isWinner = p.id == _winnerId;
          final cards = _remain[p.id] ?? 0;
          final idx = players.indexWhere((pl) => pl.id == p.id);
          final color = AppColors.playerColors[idx % AppColors.playerColors.length];

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isWinner ? AppColors.positiveScore.withValues(alpha: 0.4) : AppColors.cardBorder,
                width: isWinner ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  radius: 14,
                  child: Text(p.name[0], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isWinner ? '🏆 ${p.name} · 0张' : p.name,
                    style: TextStyle(
                      color: isWinner ? AppColors.positiveScore : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!isWinner) ...[
                  _circleBtn(Icons.remove, color, () {
                    if (cards > 0) setState(() => _remain[p.id] = cards - 1);
                  }),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '$cards',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _circleBtn(Icons.add, color, () {
                    if (cards < 54) setState(() => _remain[p.id] = cards + 1);
                  }),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  // ─── Extra Rules ───────────────────────────────────────

  Widget _buildExtraRules() {
    // Calculate penalty preview text
    String penaltyText = '输家惩罚: 牌数';
    if (_singleCardScore == 0) { penaltyText += '（独牌不计）'; }
    if (_bombCount > 0) { penaltyText += ' + ${_bombCount * 10}（炸弹）'; }
    if (_spring) { penaltyText += ' ×2（春天）'; }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          // Spring toggle
          Row(
            children: [
              const Text('春天', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _spring = !_spring),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _spring ? AppColors.positiveScore : AppColors.surfaceLight,
                  ),
                  alignment: _spring ? Alignment.centerRight : Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bomb counter
          Row(
            children: [
              const Text('炸弹', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              _circleBtn(Icons.remove, AppColors.warning, () {
                if (_bombCount > 0) setState(() => _bombCount--);
              }),
              const SizedBox(width: 10),
              SizedBox(
                width: 48,
                child: Text(
                  '$_bombCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 10),
              _circleBtn(Icons.add, AppColors.warning, () => setState(() => _bombCount++)),
            ],
          ),
          if (_bombCount > 0 || _spring || _singleCardScore == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(penaltyText, style: const TextStyle(color: AppColors.warning, fontSize: 11)),
            ),
          const SizedBox(height: 12),
          // Single card rule
          Row(
            children: [
              const Text('独牌积分', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              _circleBtn(Icons.remove, AppColors.primary, () {
                if (_singleCardScore > 0) setState(() => _singleCardScore--);
              }),
              const SizedBox(width: 10),
              SizedBox(
                width: 48,
                child: Text(
                  '$_singleCardScore',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _singleCardScore == 0 ? AppColors.positiveScore : AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _circleBtn(Icons.add, AppColors.primary, () => setState(() => _singleCardScore++)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _singleCardScore == 0 ? '剩余1张牌不计分数' : '剩余1张牌计 $_singleCardScore 分',
            style: const TextStyle(color: AppColors.textHint, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ─── Submit Button ─────────────────────────────────────

  Widget _buildSubmitButton() {
    final enabled = _winnerId != null;
    final isEditing = _editingRoundIndex != null;
    return GestureDetector(
      onTap: enabled ? _submit : null,
      child: Container(
        width: double.infinity,
        height: 60,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: enabled ? (isEditing ? AppColors.warning : AppColors.positiveScore) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            isEditing ? '更新结算' : '确认结算',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 4),
          ),
        ),
      ),
    );
  }

  // ─── Round History ─────────────────────────────────────

  Widget _buildRoundHistory(game) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('历史局（点击可编辑）', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...game.rounds.reversed.map((round) {
          final rn = game.rounds.indexOf(round) + 1;
          final isEditingThis = _editingRoundIndex == game.rounds.indexOf(round);
          final winner = game.players.firstWhere((p) => p.id == round.winnerId);
          final wi = game.players.indexWhere((p) => p.id == round.winnerId);
          final color = AppColors.playerColors[wi % AppColors.playerColors.length];

          return GestureDetector(
            onTap: () => _loadRound(round, game.rounds.indexOf(round)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEditingThis ? AppColors.warning.withValues(alpha: 0.08) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isEditingThis ? AppColors.warning.withValues(alpha: 0.5) : AppColors.cardBorder,
                  width: isEditingThis ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('第$rn局', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      if (round.spring) ...[
                        const SizedBox(width: 6),
                        _tag('春天', AppColors.warning),
                      ],
                      if (round.bombCount > 0) ...[
                        const SizedBox(width: 6),
                        _tag('${round.bombCount}炸', AppColors.negativeScore),
                      ],
                      const Spacer(),
                      if (isEditingThis)
                        _tag('编辑中', AppColors.warning),
                      _tag('🏆 ${winner.name} 赢', color),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...round.scoreDeltas.entries.map((e) {
                    final p = game.players.firstWhere((pl) => pl.id == e.key);
                    final isPos = e.value >= 0;
                    final rem = round.remainCards[e.key] ?? 0;
                    return Row(
                      children: [
                        Expanded(child: Text('${p.name} (剩$rem张)', style: const TextStyle(fontSize: 12, color: AppColors.textHint))),
                        Text(
                          '${isPos ? '+' : ''}${e.value}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isPos ? AppColors.positiveScore : AppColors.negativeScore),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
