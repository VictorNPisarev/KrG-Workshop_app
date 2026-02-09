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

class WorkshopApp extends StatelessWidget {
  const WorkshopApp({super.key});
  
  @override
  Widget build(BuildContext context) {
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

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});
  
  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

enum AppState { loading, checkingUpdates, ready, error }

class _AppNavigatorState extends State<AppNavigator> {
  AppState _appState = AppState.loading;
  String? _error;
  AppUpdate? _availableUpdate;
  bool _dialogShown = false;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    try {
      print('🚀 Начало инициализации приложения');
      
      // Настраиваем менеджер обновлений
      GitHubUpdateManager.configure(
        repoOwner: 'VictorNPisarev',
        repoName: 'KrG-Workshop_app',
      );
      
      // 1. Инициализируем AuthProvider
      print('🔄 Инициализация AuthProvider...');
      final authProvider = Provider.of<AuthProvider>(
        context,
        listen: false,
      );
      await authProvider.initialize();
      
      // Проверяем, не было ли ошибки
      if (authProvider.error != null) {
        throw Exception(authProvider.error);
      }
      
      // 2. Проверяем обновления
      print('🔄 Проверка обновлений...');
      final update = await _checkForUpdatesWithRetry();
      
      if (update != null) {
        print('🎉 Обновление найдено, показываем диалог');
        setState(() {
          _availableUpdate = update;
          _appState = AppState.checkingUpdates;
        });
        
        // Ждем немного, чтобы анимация загрузки была видна
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Показываем диалог ОТСЮДА, не из build!
        await _showUpdateDialog(update);
        
        // После закрытия диалога переходим к приложению
        if (mounted) {
          setState(() {
            _availableUpdate = null;
            _appState = AppState.ready;
          });
        }
      } else {
        print('✅ Обновлений не найдено');
        setState(() => _appState = AppState.ready);
      }
      
    } catch (e) {
      print('❌ Ошибка инициализации: $e');
      setState(() {
        _error = e.toString();
        _appState = AppState.error;
      });
    }
  }
  
  Future<AppUpdate?> _checkForUpdatesWithRetry() async {
    try {
      final update = await GitHubUpdateManager.checkForUpdates();
      
      if (update != null) {
        // Проверяем, нужно ли показывать это обновление
        final shouldShow = await GitHubUpdateManager.shouldShowUpdate(update.versionCode);
        return shouldShow ? update : null;
      }
      return null;
    } catch (e) {
      print('⚠️ Ошибка проверки обновлений: $e');
      return null;
    }
  }
  
  Future<void> _showUpdateDialog(AppUpdate update) async {
    // Показываем диалог напрямую, без WidgetsBinding
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
    
    // 2. Если проверяем обновления ИЛИ есть обновление - показываем индикатор
    if (_appState == AppState.checkingUpdates || _availableUpdate != null) {
      return _buildUpdateCheckScreen();
    }
    
    // 3. Если всё готово - основная навигация
    if (_appState == AppState.ready) {
      // Если пользователь не авторизован - экран входа
      if (!authProvider.isAuthenticated) {
        return const LoginScreen();
      }
      
      // Если пользователь авторизован, но не выбрал рабочее место
      if (authProvider.currentWorkplace == null) {
        return const SelectWorkplaceScreen();
      }
      
      // Если все готово - главный экран
      return const HomeScreen();
    }
    
    // 4. По умолчанию - обычный сплеш
    return const SplashScreen();
  }
  
  Widget _buildUpdateCheckScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _availableUpdate != null ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
                Icon(
                  _availableUpdate != null ? Icons.update : Icons.search,
                  size: 30,
                  color: _availableUpdate != null ? Colors.blue : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _availableUpdate != null 
                ? 'Найдено обновление!'
                : 'Проверка обновлений...',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              _availableUpdate?.version ?? 'Подождите...',
              style: const TextStyle(color: Colors.grey),
            ),
            if (_availableUpdate != null) ...[
              const SizedBox(height: 20),
              const Text(
                'Открывается диалог обновления...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
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
                    _dialogShown = false;
                  });
                  _initializeApp();
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
class UpdateDialog extends StatefulWidget {
  final AppUpdate update;
  
  const UpdateDialog({super.key, required this.update});
  
  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
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