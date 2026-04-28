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
import '../utils/app_version.dart' hide Math;


import '../utils/math_utils.dart';

class AppUpdate 
{
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
			version: json['tag_name']?.toString().replaceFirst('v', '') ?? '1.0.0',
			versionCode: int.tryParse(json['tag_name']?.toString().split('.').last ?? '1') ?? 1,
			minimumVersionCode: 1,
			downloadUrl: _extractDownloadUrl(json),
			forceUpdate: false,
			releaseNotes: _parseReleaseNotes(json['body']),
			fileSize: 0,
			checksum: '',
			fileName: _extractFileName(json),
		);
	}

	static String _extractDownloadUrl(Map<String, dynamic> json)
	{
		// Ищем APK файл в assets
		final assets = json['assets'] as List<dynamic>? ?? [];
	
		for (final asset in assets)
		{
			final name = asset['name']?.toString() ?? '';
		
			if (name.endsWith('.apk'))
			{
				return asset['browser_download_url']?.toString() ?? '';
			}
		}
		return '';
	}

	static String _extractFileName(Map<String, dynamic> json)
	{
		final assets = json['assets'] as List<dynamic>? ?? [];
		
		for (final asset in assets)
		{
			final name = asset['name']?.toString() ?? '';
			
			if (name.endsWith('.apk'))
			{
				return name;
			}
		}
		return 'app-release.apk';
	}

	static List<String> _parseReleaseNotes(String? body)
	{
		if (body == null || body.isEmpty)
		{
			return ['Исправлены ошибки, улучшена производительность'];
		}
		
		// Парсим релиз ноутсы
		final List<String> notes = [];
		final lines = body.split('\n');
		
		for (final line in lines)
		{
			final trimmed = line.trim();
			
			if (trimmed.startsWith('-') || trimmed.startsWith('*') || trimmed.startsWith('•'))
			{
				notes.add(trimmed.substring(1).trim());
			}
			else if (trimmed.isNotEmpty && !trimmed.startsWith('#'))
			{
				// Добавляем обычные строки (кроме заголовков)
				notes.add(trimmed);
			}
		}
		
		return notes.isNotEmpty ? notes : ['Исправлены ошибки, улучшена производительность'];
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
	static String _repoName = 'KrG.Workshop.App'; //'KrG-Workshop_app';
	
	// Получаем URL для GitHub API
	static String get _updateJsonUrl => 
			'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';
	
	static final Dio _dio = Dio(BaseOptions(
		connectTimeout: const Duration(seconds: 10),
		receiveTimeout: const Duration(seconds: 10),
	));
	
	// Настройка репозитория
	static void configure({required String repoOwner, required String repoName, String branch = 'main'})
	{
		_repoOwner = repoOwner;
		_repoName = repoName;
	}
	
	// Проверка обновлений
	static Future<AppUpdate?> checkForUpdates() async
	{
		try
		{
			print('🔄 Проверка обновлений через GitHub API...');
			print('📡 URL: $_updateJsonUrl');
			
			// Получаем текущую версию приложения
			final packageInfo = await PackageInfo.fromPlatform();
			final currentVersion = AppVersion.fromPackageInfo(packageInfo);
			print('📱 Текущая версия: $currentVersion');
			
			final headers =
			{
				'Accept': 'application/vnd.github.v3+json',
				'User-Agent': 'KrG-Workshop-App',
			};
			
			
			final response = await _dio.get(_updateJsonUrl, options: Options(headers: headers));
			
			print('📥 Ответ получен, статус: ${response.statusCode}');
			
			if (response.statusCode == 200)
			{
				final releaseData = response.data as Map<String, dynamic>;
				
				// Отладочная информация
				print('✅ Релиз найден: ${releaseData['tag_name']}');
				print('📝 Название релиза: ${releaseData['name']}');
				
				// Парсим версию из тега (убираем "v" в начале если есть)
				final releaseTag = releaseData['tag_name']?.toString() ?? 'v1.0.0';
				final releaseVersionStr = releaseTag.startsWith('v') 
						? releaseTag.substring(1) 
						: releaseTag;
				
				// Пробуем получить build number из тега (последняя часть)
				final parts = releaseVersionStr.split('.');
				final releaseBuildNumber = parts.length > 2 
						? int.tryParse(parts.last) ?? 1 
						: 1;
				
				final releaseVersion = AppVersion(releaseVersionStr, releaseBuildNumber);
				print('🎯 Версия релиза: $releaseVersion');
				
				// Сравниваем версии
				if (releaseVersion.isNewerThan(currentVersion))
				{
					print('🎉 Доступно обновление!');
					
					// Создаем объект обновления
					return AppUpdate.fromJson(releaseData);
				}
				else
				{
					print('✅ У вас последняя версия');
					return null;
				}
			}
			else
			{
				print('❌ Ошибка API: ${response.statusCode}');
				if (response.data != null)
				{
					print('📄 Ответ: ${response.data}');
				}
				return null;
			}
		}
		catch (e)
		{
			print('❌ Ошибка проверки обновлений: $e');
			return null;
		}
	}

	// Сравнение версий
	static bool _isNewerVersion(String newVersion, String currentVersion)
	{
		try
		{
			final newParts = newVersion.split('.').map(int.parse).toList();
			final currentParts = currentVersion.split('.').map(int.parse).toList();
			
			for (int i = 0; i < Math.max(newParts.length, currentParts.length); i++) {
				final newPart = i < newParts.length ? newParts[i] : 0;
				final currentPart = i < currentParts.length ? currentParts[i] : 0;
				
				if (newPart > currentPart) return true;
				if (newPart < currentPart) return false;
			}
			return false;
		} catch (e) {
			print('⚠️ Ошибка сравнения версий: $e');
			return false;
		}
	}

	// Показать диалог обновления
	static Future<void> showUpdateDialog(BuildContext context, AppUpdate updateInfo) async
	{
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
	) async 
	{
		try 
		{
			print('📥 Начинаем загрузку обновления...');
			
			// Для Android запрашиваем необходимые разрешения
			if (Platform.isAndroid) 
			{
				print('🤖 Android устройство, проверяем разрешения');
				
				// 1. Разрешение на установку APK (для Android 8.0+)
				try 
				{
					final installStatus = await Permission.requestInstallPackages.request();
					
					if (installStatus.isGranted) 
					{
						print('✅ Разрешение на установку APK предоставлено');
					} 
					else 
					{
						print('⚠️ Разрешение на установку APK не предоставлено, пользователь должен включить "Неизвестные источники" вручную');
					}
				} 
				catch (e) 
				{
					print('ℹ️ Permission.requestInstallPackages не доступно: $e');
				}
				
				// 2. Разрешение на запись (для старых версий Android)
				try 
				{
					final storageStatus = await Permission.storage.request();
					if (storageStatus.isGranted) 
					{
						print('✅ Разрешение на запись предоставлено');
					} 
					else 
					{
						print('⚠️ Разрешение на запись не предоставлено, используем кэш приложения');
					}
				} 
				catch (e) 
				{
					print('ℹ️ Permission.storage не доступно: $e');
				}
			}
			
			// Скачиваем APK во временную директорию
			final tempDir = await getTemporaryDirectory();
			final filePath = '${tempDir.path}/${updateInfo.fileName}';
			final file = File(filePath);
			
			// Удаляем старый файл, если существует
			if (await file.exists()) 
			{
				await file.delete();
				print('🗑️ Удален старый файл обновления');
			}
			
			print('📥 Скачиваем APK: ${updateInfo.downloadUrl}');
			print('📁 Сохраняем в: $filePath');
			
			// Скачивание с прогрессом
			await _dio.download(
				updateInfo.downloadUrl,
				filePath,
				onReceiveProgress: (received, total) 
				{
					if (total != -1 && onProgress != null) 
					{
						final progress = received / total;
						onProgress(progress);
						if (received % (100 * 1024) == 0) // Каждые 100KB
						{ 
							print('📊 Прогресс: ${(progress * 100).toStringAsFixed(1)}%');
						}
					}
				},
				options: Options(
					headers: {'User-Agent': 'Workshop-App-Updater'},
					receiveTimeout: const Duration(minutes: 10),
				),
			);
			
			// Проверяем, что файл скачан
			final fileSize = await file.length();
			print('✅ Файл скачан успешно');
			print('📊 Размер файла: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
			
			// Показываем уведомление об успешной загрузке
			if (context.mounted) 
			{
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text('Обновление скачано. Начинаем установку...'),
						duration: Duration(seconds: 2),
					),
				);
			}
			
			// Запускаем установку
			await _installApk(filePath);
			
		} 
		catch (e) 
		{
			print('❌ Ошибка при загрузке обновления: $e');
			
			// Показываем ошибку пользователю
			if (context.mounted) 
			{
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text('Ошибка при загрузке обновления: $e'),
						backgroundColor: Colors.red,
						duration: Duration(seconds: 5),
					),
				);
			}
			
			rethrow;
		}
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
	static Future<bool> shouldShowUpdate(int versionCode) async
	{
		final prefs = await SharedPreferences.getInstance();
		final lastSkippedVersion = prefs.getInt('last_skipped_version') ?? 0;
		
		// Не показываем, если пользователь уже пропускал эту версию
		return versionCode > lastSkippedVersion;
	}
	
	// Сохранить, что пользователь пропустил эту версию
	static Future<void> markAsSkipped(int versionCode) async
	{
		final prefs = await SharedPreferences.getInstance();
		await prefs.setInt('last_skipped_version', versionCode);
	}
}

// Диалог обновления
class _UpdateDialog extends StatefulWidget
{
	final AppUpdate updateInfo;
	final String currentVersion;
	
	const _UpdateDialog({
		required this.updateInfo,
		required this.currentVersion,
	});
	
	@override
	State<_UpdateDialog> createState() => __UpdateDialogState();
}

class __UpdateDialogState extends State<_UpdateDialog>
{
	bool _isDownloading = false;
	double _downloadProgress = 0.0;
	
	@override
	Widget build(BuildContext context)
	{
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
										...widget.updateInfo.releaseNotes.take(5).map((note) => 
											Padding(
												padding: const EdgeInsets.only(left: 8, bottom: 4),
												child: Text('• $note'),
											)
										).toList(),
									],
									
									const SizedBox(height: 16),
									Text(
										'Рекомендуем установить обновление.',
										style: TextStyle(color: Colors.grey[700]),
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
						child: const Text('Позже'),
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