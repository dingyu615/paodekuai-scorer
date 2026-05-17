import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../models/player.dart';
import '../../providers/game_provider.dart';
import '../../services/hive_service.dart';
import '../../routes/app_routes.dart';

class CreateGamePage extends StatefulWidget {
  const CreateGamePage({super.key});

  @override
  State<CreateGamePage> createState() => _CreateGamePageState();
}

class _CreateGamePageState extends State<CreateGamePage> {
  final _hive = HiveService();
  final _controllers = <TextEditingController>[];
  final _focusNodes = <FocusNode>[];
  late int _playerCount;

  @override
  void initState() {
    super.initState();
    _playerCount = _hive.getLastPlayerCount();
    final recentNames = _hive.getRecentNames();
    for (var i = 0; i < 6; i++) {
      String defaultName = '玩家${i + 1}';
      if (i < recentNames.length) { defaultName = recentNames[i]; }
      _controllers.add(TextEditingController(text: defaultName));
      _focusNodes.add(FocusNode());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  bool get _allValid {
    final names = _controllers.take(_playerCount).map((c) => c.text.trim()).toList();
    return names.every((n) => n.isNotEmpty) && names.toSet().length == names.length;
  }

  void _onNameChipTap(String name) {
    for (var i = 0; i < _playerCount; i++) {
      if (_controllers[i].text.trim().isEmpty) {
        _controllers[i].text = name;
        setState(() {});
        return;
      }
    }
  }

  void _start() {
    final names = _controllers.take(_playerCount).map((c) => c.text.trim()).toList();

    if (names.any((n) => n.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写所有玩家名字'), backgroundColor: AppColors.negativeScore),
      );
      return;
    }
    if (names.toSet().length != names.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('玩家名字不能重复'), backgroundColor: AppColors.negativeScore),
      );
      return;
    }

    _hive.saveRecentNames(names);
    _hive.saveLastPlayerCount(_playerCount);

    final players = <Player>[];
    for (var i = 0; i < names.length; i++) {
      players.add(Player(id: const Uuid().v4(), name: names[i]));
    }

    context.read<GameProvider>().createGame(
      players: players,
      singleCardScore: _hive.getSingleCardScore(),
      enableSpring: _hive.getEnableSpring(),
      enableBomb: _hive.getEnableBomb(),
    );
    Navigator.pushNamed(context, AppRoutes.game);
  }

  @override
  Widget build(BuildContext context) {
    final recentNames = _hive.getRecentNames();
    final showRecent = recentNames.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('创建牌局', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                _buildPlayerCountPills(),
                const SizedBox(height: 28),
                _buildNameInputs(),
                if (showRecent) ...[
                  const SizedBox(height: 20),
                  _buildRecentChips(recentNames),
                ],
                const SizedBox(height: 24),
                const SizedBox(height: 100),
              ],
            ),
          ),
          _buildStartButton(),
        ],
      ),
    );
  }

  // ─── Player Count Pills ───────────────────────────────

  Widget _buildPlayerCountPills() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('玩家人数', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [2, 3, 4].map((n) {
            final selected = _playerCount == n;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _playerCount = n),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: EdgeInsets.only(right: n < 4 ? 10 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                      child: Text('$n人'),
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

  // ─── Name Inputs ──────────────────────────────────────

  Widget _buildNameInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('玩家昵称', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Column(
            key: ValueKey(_playerCount),
            children: List.generate(_playerCount, (i) {
              final color = AppColors.playerColors[i % AppColors.playerColors.length];
              final initial = _controllers[i].text.trim().isNotEmpty ? _controllers[i].text.trim()[0] : '${i + 1}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                          textInputAction: i < _playerCount - 1 ? TextInputAction.next : TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) {
                            if (i < _playerCount - 1) {
                              _focusNodes[i + 1].requestFocus();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: '输入昵称',
                            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: AppColors.surface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ─── Recent Name Chips ────────────────────────────────

  Widget _buildRecentChips(List<String> recentNames) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('最近玩家', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recentNames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final name = recentNames[i];
              return GestureDetector(
                onTap: () => _onNameChipTap(name),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder, width: 0.5),
                  ),
                  child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Start Button ─────────────────────────────────────

  Widget _buildStartButton() {
    final enabled = _allValid;
    return GestureDetector(
      onTap: enabled ? _start : null,
      child: Container(
        width: double.infinity,
        height: 60,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        decoration: BoxDecoration(
          color: enabled ? AppColors.positiveScore : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('开始游戏', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 4)),
        ),
      ),
    );
  }
}
