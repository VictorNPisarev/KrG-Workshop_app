import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget
{
    const SplashScreen({super.key});
    
    @override
    State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
{
    bool _initialized = false;
    String? _error;
    
    @override
    void didChangeDependencies()
    {
        super.didChangeDependencies();
        
        if (!_initialized)
        {
            _initialized = true;
            _initializeApp();
        }
    }
    
    Future<void> _initializeApp() async
    {
        try
        {
            print('🔄 SplashScreen: начата инициализация приложения');
            
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            await authProvider.initialize();
            
            print('✅ SplashScreen: инициализация завершена');
            
            // Если есть ошибка в authProvider, показываем ее
            if (authProvider.error != null && mounted)
            {
                setState(() {
                    _error = authProvider.error;
                });
            }
        }
        catch (e, stackTrace)
        {
            print('❌ SplashScreen: критическая ошибка инициализации');
            print('Ошибка: $e');
            print('Стек: $stackTrace');
            
            if (mounted)
            {
                setState(() {
                    _error = 'Критическая ошибка: $e';
                });
            }
        }
    }
    
    @override
    Widget build(BuildContext context)
    {
        final authProvider = Provider.of<AuthProvider>(context);
        
        // Если есть ошибка - показываем экран ошибки
        if (_error != null || authProvider.error != null)
        {
            return _buildErrorScreen(_error ?? authProvider.error!);
        }
        
        // Если идет загрузка - показываем сплеш
        if (authProvider.isLoading)
        {
            return _buildLoadingScreen();
        }
        
        // Если загрузка завершена, но еще не прошла секунда (чтобы сплеш был виден)
        // Навигацию обработает AppNavigator
        return _buildLoadingScreen();
    }
    
    Widget _buildLoadingScreen()
    {
        return Scaffold(
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                            'Загрузка приложения...',
                            style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                            'Версия 1.0.0',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
    
    Widget _buildErrorScreen(String error)
    {
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
                            Text(
                                'Ошибка загрузки',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.red,
                                ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                                error,
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
                                        _initialized = false;
                                    });
                                },
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                                icon: const Icon(Icons.settings),
                                label: const Text('Настройки сети'),
                                onPressed: () {
                                    // Можно открыть настройки устройства
                                    // или показать инструкцию
                                },
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}