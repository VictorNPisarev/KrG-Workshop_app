import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workshop_app/services/github_update_manager.dart';
import 'providers/auth_provider.dart';
import 'providers/orders_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/select_workplace_screen.dart';
import 'screens/home_screen.dart';

void main() {
	runApp(const WorkshopApp());
}

class WorkshopApp extends StatelessWidget
{
	const WorkshopApp({super.key});
	
	@override
	Widget build(BuildContext context)
	{
		return MultiProvider(
			providers: [
				ChangeNotifierProvider(create: (_) => AuthProvider()),
				ChangeNotifierProvider(create: (_) => OrdersProvider()),
			],
			child: MaterialApp(
				title: 'Workshop App',
				theme: ThemeData(
					primarySwatch: Colors.blue,
					useMaterial3: true,
				),
				home: const AppNavigator(),
			),
		);
	}
}

class AppNavigator extends StatefulWidget
{
	const AppNavigator({super.key});
	
	@override
	State<AppNavigator> createState() => _AppNavigatorState();
}

enum AppState { loading, checkingUpdates, ready, error }

class _AppNavigatorState extends State<AppNavigator>
{
	AppState _appState = AppState.loading;
	String? _error;
	AppUpdate? _availableUpdate;
	bool _updatesChecked = false; // Новый флаг
	
	@override
	void initState()
	{
		super.initState();
		// Запускаем только инициализацию auth, проверку обновлений сделаем отдельно
		_initializeAuth();
	}
	
	Future<void> _initializeAuth() async
	{
		try
		{
			print('🔄 Инициализация AuthProvider...');
			final authProvider = Provider.of<AuthProvider>(context, listen: false);
			await authProvider.initialize();
			
			if (authProvider.error != null)
			{
				throw Exception(authProvider.error);
			}
			
			// Auth инициализирован, можно проверять обновления
			if (mounted)
			{
				setState(() => _appState = AppState.ready);
				// Проверку обновлений запускаем отдельно
				_checkUpdates();
			}
		}
		catch (e)
		{
			print('❌ Ошибка инициализации: $e');
			if (mounted)
			{
				setState((){
					_error = e.toString();
					_appState = AppState.error;
				});
			}
		}
	}
	
	Future<void> _checkUpdates() async
	{
		try
		{
			print('🔄 Проверка обновлений...');
			
			final update = await GitHubUpdateManager.checkForUpdates();
			
			if (update != null)
			{
				print('🎉 Обновление найдено: ${update.version}');

				/*final shouldShow = await GitHubUpdateManager.shouldShowUpdate(update.versionCode);
				
				if (shouldShow && mounted)
				{
					// Сохраняем обновление
					_availableUpdate = update;
					_updatesChecked = true;
					
					// Показываем диалог
					//await _showUpdateDialog(update);
					await GitHubUpdateManager.showUpdateDialog(context, update);
				}*/

				if (mounted)
				{
					await GitHubUpdateManager.showUpdateDialog(context, update);
				}

			}
			else
			{
				print('✅ Обновлений не найдено');
			}
		}
		catch (e)
		{
			print('⚠️ Ошибка проверки обновлений: $e');
		}
	}
	
	Future<void> _showUpdateDialog(AppUpdate update) async
	{
		await showDialog(
			context: context,
			barrierDismissible: false,
			builder: (context) => UpdateDialog(update: update),
		);
	}
	
	@override
	Widget build(BuildContext context) {
		final authProvider = Provider.of<AuthProvider>(context);
		
		// 1. Если есть ошибка - показываем экран ошибки
		if (_appState == AppState.error) {
			return _buildErrorScreen();
		}
		
		// 2. Если идёт загрузка - показываем сплеш
		if (_appState == AppState.loading || authProvider.isLoading) {
			return const SplashScreen();
		}
		
		// 3. Основная навигация
		if (_appState == AppState.ready) {
			// Если есть обновление И мы его еще не показывали
			if (_availableUpdate != null && !_updatesChecked) {
				// Показываем диалог обновления сразу
				WidgetsBinding.instance.addPostFrameCallback((_) {
					_updatesChecked = true; // Помечаем как показанное
					_showUpdateDialog(_availableUpdate!);
				});
			}
			
			// Показываем основной интерфейс
			if (!authProvider.isAuthenticated) {
				return const LoginScreen();
			}
			
			if (authProvider.currentWorkplace == null) {
				return const SelectWorkplaceScreen();
			}
			
			return const HomeScreen();
		}
		
		return const SplashScreen();
	}
	
	Widget _buildErrorScreen() {
		return Scaffold(
			body: Center(
				child: Padding(
					padding: const EdgeInsets.all(24),
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							const Icon(Icons.error_outline, size: 64, color: Colors.red),
							const SizedBox(height: 20),
							const Text(
								'Ошибка запуска',
								style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
							),
							const SizedBox(height: 16),
							Text(
								_error ?? 'Неизвестная ошибка',
								textAlign: TextAlign.center,
								style: const TextStyle(color: Colors.grey),
							),
							const SizedBox(height: 32),
							ElevatedButton.icon(
								icon: const Icon(Icons.refresh),
								label: const Text('Повторить'),
								onPressed: () {
									setState(() {
										_error = null;
										_appState = AppState.loading;
										_availableUpdate = null;
										_updatesChecked = false;
									});
									_initializeAuth();
								},
							),
						],
					),
				),
			),
		);
	}
}
// Упрощенный диалог обновления
class UpdateDialog extends StatefulWidget
{
	final AppUpdate update;
	
	const UpdateDialog({super.key, required this.update});
	
	@override
	State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
{
	bool _isDownloading = false;
	double _progress = 0.0;
	
	@override
	Widget build(BuildContext context) {
		return AlertDialog(
			title: const Text('Доступно обновление'),
			content: _isDownloading
					? Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								LinearProgressIndicator(value: _progress),
								const SizedBox(height: 16),
								Text('${(_progress * 100).toInt()}%'),
								const SizedBox(height: 8),
								const Text('Скачивание...'),
							],
						)
					: Column(
							mainAxisSize: MainAxisSize.min,
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text('Новая версия: ${widget.update.version}'),
								const SizedBox(height: 16),
								if (widget.update.releaseNotes.isNotEmpty) ...[
									const Text(
										'Что нового:',
										style: TextStyle(fontWeight: FontWeight.bold),
									),
									const SizedBox(height: 8),
									...widget.update.releaseNotes.take(3).map((note) => 
										Padding(
											padding: const EdgeInsets.only(left: 8, bottom: 4),
											child: Text('• $note'),
										)
									).toList(),
									const SizedBox(height: 16),
								],
								Text(
									'Рекомендуем установить обновление.',
									style: TextStyle(color: Colors.grey[700]),
								),
							],
						),
			actions: [
				if (!_isDownloading)
					TextButton(
						onPressed: () {
							GitHubUpdateManager.markAsSkipped(widget.update.versionCode);
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
				widget.update,
				(progress) => setState(() => _progress = progress),
			);
			
			if (context.mounted) {
				Navigator.pop(context);
			}
		} catch (e) {
			if (context.mounted) {
				setState(() => _isDownloading = false);
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text('Ошибка загрузки: $e'),
						backgroundColor: Colors.red,
					),
				);
			}
		}
	}
}