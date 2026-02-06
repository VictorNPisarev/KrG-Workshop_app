import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class AppUpdate {
  final String version;
  final int versionCode;
  final int minimumVersionCode;
  final String downloadUrl;
  final bool forceUpdate;
  final List<String> releaseNotes;
  final int fileSize;
  final String checksum;
  final String fileName;

  AppUpdate({
    required this.version,
    required this.versionCode,
    required this.minimumVersionCode,
    required this.downloadUrl,
    required this.forceUpdate,
    required this.releaseNotes,
    required this.fileSize,
    required this.checksum,
    required this.fileName,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> json) 
  {
      return AppUpdate(
        version: json['version'] as String,
        versionCode: json['version_code'] as int,
        minimumVersionCode: json['minimum_version_code'] as int,
        downloadUrl: json['download_url'] as String,
        forceUpdate: json['force_update'] ?? false,
        releaseNotes: List<String>.from(json['release_notes'] ?? []),
        fileSize: json['file_size'] as int,
        checksum: json['checksum'] as String,
        fileName: json['file_name'] as String,
      );
  }

  Map<String, dynamic> toJson() => 
  {
      'version': version,
      'version_code': versionCode,
      'minimum_version_code': minimumVersionCode,
      'download_url': downloadUrl,
      'force_update': forceUpdate,
      'release_notes': releaseNotes,
      'file_size': fileSize,
      'checksum': checksum,
      'file_name': fileName,
  };
}

class GitHubUpdateManager 
{
  // Конфигурация
  static String _repoOwner = 'VictorNPisarev';
  static String _repoName = 'KrG-Workshop_app';
  static String _branch = 'main';
  
  // Получаем URL для update.json (raw-ссылка)
  static String get _updateJsonUrl => 
      'https://github.com/$_repoOwner/$_repoName/releases/latest/download/update.json';
  
  static final Dio _dio = Dio();
  
  // Настройка репозитория (можно менять в рантайме)
  static void configure({
    required String repoOwner,
    required String repoName,
    String branch = 'main',
  }) {
    _repoOwner = repoOwner;
    _repoName = repoName;
    _branch = branch;
  }
  
  // Проверка обновлений
  static Future<AppUpdate?> checkForUpdates() async {
    try {
      print('🔄 Проверка обновлений на GitHub...');
      
      // Загружаем update.json
      final response = await _dio.get(
        _updateJsonUrl,
        options: Options(
          headers: {'User-Agent': 'Flutter-App'},
        ),
      );
      
      if (response.statusCode == 200) {
        final updateInfo = AppUpdate.fromJson(response.data);
        
        // Получаем текущую версию
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;
        
        print('📱 Текущая: $currentVersionCode, доступна: ${updateInfo.versionCode}');
        
        if (updateInfo.versionCode > currentVersionCode) {
          print('🆕 Найдено обновление: ${updateInfo.version}');
          return updateInfo;
        } else {
          print('✅ У вас последняя версия');
        }
      } else {
        print('❌ GitHub вернул статус: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка проверки обновлений: $e');
    }
    return null;
  }
  
  // Показать диалог обновления
  static Future<void> showUpdateDialog(
    BuildContext context,
    AppUpdate updateInfo,
  ) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => _UpdateDialog(
        updateInfo: updateInfo,
        currentVersion: currentVersion,
      ),
    );
  }
  
  // Скачать и установить обновление
  static Future<void> downloadAndInstall(
    BuildContext context,
    AppUpdate updateInfo,
    Function(double)? onProgress,
  ) async {
    try {
      // Запрашиваем разрешения для Android
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          throw Exception('Нет разрешения на запись в хранилище');
        }
        
        // Для Android 8+
        if (await Permission.requestInstallPackages.isGranted) {
          await Permission.requestInstallPackages.request();
        }
      }
      
      // Скачиваем APK
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${updateInfo.fileName}';
      final file = File(filePath);
      
      // Удаляем старый файл, если существует
      if (await file.exists()) {
        await file.delete();
      }
      
      print('📥 Начинаем скачивание: ${updateInfo.downloadUrl}');
      
      // GitHub требует User-Agent
      await _dio.download(
        updateInfo.downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            final progress = received / total;
            onProgress(progress);
          }
        },
        options: Options(
          headers: {'User-Agent': 'Flutter-App'},
        ),
      );
      
      // Проверяем контрольную сумму
      await _verifyChecksum(filePath, updateInfo.checksum);
      
      print('✅ Файл скачан: $filePath');
      
      // Устанавливаем приложение
      await _installApk(filePath);
      
    } catch (e) {
      print('❌ Ошибка при обновлении: $e');
      rethrow;
    }
  }
  
  // Проверка контрольной суммы
  static Future<void> _verifyChecksum(
    String filePath, 
    String expectedChecksum
  ) async {
    if (expectedChecksum.isEmpty) {
      print('⚠️ Контрольная сумма не указана, пропускаем проверку');
      return;
    }
    
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = md5.convert(bytes);
    final actualChecksum = digest.toString();
    
    if (actualChecksum != expectedChecksum) {
      throw Exception('Контрольная сумма не совпадает. Ожидалось: $expectedChecksum, получили: $actualChecksum');
    }
    
    print('✅ Контрольная сумма проверена');
  }
  
  // Установка APK
  static Future<void> _installApk(String filePath) async {
    if (Platform.isAndroid) {
      await OpenFile.open(filePath);
      print('🚀 Запущена установка APK');
    } else {
      throw Exception('Автоматическая установка поддерживается только на Android');
    }
  }
  
  // Проверка, пропускал ли пользователь это обновление
  static Future<bool> shouldShowUpdate(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSkippedVersion = prefs.getInt('last_skipped_version') ?? 0;
    
    // Не показываем, если пользователь уже пропускал эту версию
    return versionCode > lastSkippedVersion;
  }
  
  // Сохранить, что пользователь пропустил эту версию
  static Future<void> markAsSkipped(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_skipped_version', versionCode);
  }
}

// Диалог обновления
class _UpdateDialog extends StatefulWidget {
  final AppUpdate updateInfo;
  final String currentVersion;
  
  const _UpdateDialog({
    required this.updateInfo,
    required this.currentVersion,
  });
  
  @override
  State<_UpdateDialog> createState() => __UpdateDialogState();
}

class __UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Доступно обновление'),
      content: _isDownloading
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: _downloadProgress),
                const SizedBox(height: 16),
                Text('${(_downloadProgress * 100).toInt()}%'),
                const SizedBox(height: 8),
                const Text('Скачивание...'),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Текущая версия: ${widget.currentVersion}'),
                  Text('Новая версия: ${widget.updateInfo.version}'),
                  const SizedBox(height: 16),
                  
                  if (widget.updateInfo.releaseNotes.isNotEmpty) ...[
                    const Text(
                      'Что нового:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...widget.updateInfo.releaseNotes.map((note) => 
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Text('• $note'),
                      )
                    ).toList(),
                  ],
                  
                  const SizedBox(height: 16),
                  Text(
                    'Размер: ${(widget.updateInfo.fileSize / (1024 * 1024)).toStringAsFixed(1)} MB',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
      actions: [
        if (!widget.updateInfo.forceUpdate && !_isDownloading)
          TextButton(
            onPressed: () async {
              await GitHubUpdateManager.markAsSkipped(widget.updateInfo.versionCode);
              Navigator.pop(context);
            },
            child: const Text('Пропустить'),
          ),
        
        if (!_isDownloading)
          ElevatedButton(
            onPressed: () => _startDownload(context),
            child: const Text('Обновить'),
          ),
      ],
    );
  }
  
  void _startDownload(BuildContext context) async {
    setState(() => _isDownloading = true);
    
    try {
      await GitHubUpdateManager.downloadAndInstall(
        context,
        widget.updateInfo,
        (progress) {
          setState(() => _downloadProgress = progress);
        },
      );
      
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Ошибка: $e');
        setState(() => _isDownloading = false);
      }
    }
  }
  
  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}