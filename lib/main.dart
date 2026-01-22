
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/orders_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/select_workplace_screen.dart';
import 'screens/home_screen.dart';

void main()
{
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
                routes: {
                    '/login': (context) => const LoginScreen(),
                    '/select-workplace': (context) => const SelectWorkplaceScreen(),
                    '/home': (context) => const HomeScreen(),
                },
            ),
        );
    }
}

// Главный навигатор приложения
class AppNavigator extends StatelessWidget
{
    const AppNavigator({super.key});
    
    @override
    Widget build(BuildContext context)
    {
        final authProvider = Provider.of<AuthProvider>(context);
        
        // Пока идет загрузка
        if (authProvider.isLoading)
        {
            return const SplashScreen();
        }
        
        // Если пользователь не авторизован - экран входа
        if (!authProvider.isAuthenticated)
        {
            return const LoginScreen();
        }
        
        // Если пользователь авторизован, но не выбрал рабочее место
        if (authProvider.currentWorkplace == null)
        {
            return const SelectWorkplaceScreen();
        }
        
        // Если все готово - главный экран
        return const HomeScreen();
    }
}