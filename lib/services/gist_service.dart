import 'dart:convert';
import 'package:dio/dio.dart';
import '../data/models/player_progress_model.dart';

class GistService {
  final Dio _dio;
  String? _gistId;
  static const _fileName = 'dol-progress.json';

  GistService({required Dio dio}) : _dio = dio;

  /// Gist에서 진행 상태 로드
  Future<PlayerProgress?> loadProgress(String token) async {
    _dio.options.headers['Authorization'] = 'Bearer $token';

    final response = await _dio.get('https://api.github.com/gists');
    final gists = response.data as List;

    for (final gist in gists) {
      final files = gist['files'] as Map<String, dynamic>;
      if (files.containsKey(_fileName)) {
        _gistId = gist['id'] as String;
        final content = files[_fileName]['content'] as String;
        final json = jsonDecode(content) as Map<String, dynamic>;
        return PlayerProgress.fromJson(json);
      }
    }

    return null;
  }

  /// Gist에 진행 상태 저장
  Future<void> saveProgress(String token, PlayerProgress progress) async {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    final content = formatProgressToJson(progress.toJson());

    if (_gistId != null) {
      await _dio.patch(
        'https://api.github.com/gists/$_gistId',
        data: {
          'files': {
            _fileName: {'content': content},
          },
        },
      );
    } else {
      final response = await _dio.post(
        'https://api.github.com/gists',
        data: {
          'description': 'Dev Quest Library - 학습 진행 상태',
          'public': false,
          'files': {
            _fileName: {'content': content},
          },
        },
      );
      _gistId = response.data['id'] as String;
    }
  }

  static String formatProgressToJson(Map<String, dynamic> data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
