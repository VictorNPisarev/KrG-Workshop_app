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
    @override
    void initState()
    {
        super.initState();
        _initializeApp();
    }
    
    Future<void> _initializeApp() async
    {
        final authProvider = context.read<AuthProvider>();
        await authProvider.initialize();
    }
    
    @override
    Widget build(BuildContext context)
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
                    ],
                ),
            ),
        );
    }
}