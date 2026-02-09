// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        routes: {
          '/login': (context) => const LoginScreen(),
          '/select-workplace': (context) => const SelectWorkplaceScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});
  
  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  bool _updateChecked = false;
  bool _showUpdateDialog = false;
  AppUpdate? _availableUpdate;
  
  @override
  void initState() {
    super.initState();
    
    // Настраиваем GitHub Update Manager
    GitHubUpdateManager.configure(
      repoOwner: 'VictorNPisarev',
      repoName: 'KrG-Workshop_app',
    );
    
    // Проверяем обновления через 2 секунды после запуска
    Future.delayed(const Duration(seconds: 2), () {
      _checkForUpdates();
    });
  }
  
  Future<void> _checkForUpdates() async {
    print('🔄 Запуск проверки обновлений...');
    
    try {
      final update = await GitHubUpdateManager.checkForUpdates();
      
      if (update != null) {
        print('🎉 Найдено обновление: ${update.version}');
        
        // Проверяем, нужно ли показывать обновление
        final shouldShow = await GitHubUpdateManager.shouldShowUpdate(update.versionCode);
        
        if (shouldShow) {
          setState(() {
            _availableUpdate = update;
            _showUpdateDialog = true;
          });
        } else {
          print('ℹ️ Пользователь уже пропустил это обновление');
          setState(() => _updateChecked = true);
        }
      } else {
        print('✅ Обновлений не найдено');
        setState(() => _updateChecked = true);
      }
    } catch (e) {
      print('❌ Ошибка при проверке обновлений: $e');
      setState(() => _updateChecked = true);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Показываем диалог обновления если есть
    if (_showUpdateDialog && _availableUpdate != null && context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUpdateDialog = false;
        GitHubUpdateManager.showUpdateDialog(context, _availableUpdate!).then((_) {
          setState(() => _updateChecked = true);
        });
      });
    }
    
    // Пока идет проверка обновлений и загрузка
    if (!_updateChecked && authProvider.isLoading) {
      return const SplashScreen();
    }
    
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
}