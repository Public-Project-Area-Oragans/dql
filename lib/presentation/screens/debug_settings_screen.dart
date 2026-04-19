import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/providers/claude_api_providers.dart';

/// P0-5 NPC-3: 개인 P0용 최소 설정 화면.
///
/// - Claude API 키 입력/저장/삭제.
/// - 키 보관: Hive `Box<String>('auth')` 평문 (개인 P0 한정).
/// - 배포 자산에 키 포함 금지 — 사용자 수동 입력 필수.
class DebugSettingsScreen extends ConsumerStatefulWidget {
  const DebugSettingsScreen({super.key});

  @override
  ConsumerState<DebugSettingsScreen> createState() =>
      _DebugSettingsScreenState();
}

class _DebugSettingsScreenState
    extends ConsumerState<DebugSettingsScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final service = ref.read(claudeApiServiceProvider);
    final existing = await service.loadApiKey();
    if (!mounted) return;
    setState(() {
      _controller.text = existing ?? '';
      _statusMessage = existing == null
          ? '저장된 키 없음'
          : '저장된 키 있음 (마지막 4자: …${existing.substring(existing.length - 4)})';
    });
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _statusMessage = '키를 입력해주세요.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(claudeApiServiceProvider).saveApiKey(text);
      if (!mounted) return;
      setState(() => _statusMessage = '저장됨.');
    } catch (e) {
      setState(() => _statusMessage = '저장 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clear() async {
    setState(() => _loading = true);
    try {
      await ref.read(claudeApiServiceProvider).clearApiKey();
      if (!mounted) return;
      setState(() {
        _controller.clear();
        _statusMessage = '삭제됨.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkWalnut,
      appBar: AppBar(
        backgroundColor: AppColors.deepPurple,
        title: const Text(
          '🔧 설정 (debug)',
          style: TextStyle(color: AppColors.brightGold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.go('/game'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Claude API 키',
              style: TextStyle(
                color: AppColors.brightGold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '개인 P0 한정으로 Hive에 평문 저장됩니다. 공용 환경에서 사용하지 마세요.',
              style: TextStyle(color: AppColors.parchment, fontSize: 11),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              style: const TextStyle(
                color: AppColors.parchment,
                fontFamily: 'JetBrainsMono',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'sk-ant-...',
                hintStyle: TextStyle(
                  color: AppColors.parchment.withValues(alpha: 0.4),
                  fontFamily: 'JetBrainsMono',
                ),
                filled: true,
                fillColor: AppColors.deepPurple,
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.gold),
                  borderRadius: BorderRadius.circular(4),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.gold,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.darkWalnut,
                  ),
                  child: const Text('저장'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _loading ? null : _clear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold),
                  ),
                  child: const Text('삭제'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_statusMessage != null)
              Text(
                _statusMessage!,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
