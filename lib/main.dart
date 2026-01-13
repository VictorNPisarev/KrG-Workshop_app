// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Добавляем импорт

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
        return MaterialApp(
            title: 'Workshop App',
            theme: ThemeData(
                primarySwatch: Colors.blue,
                useMaterial3: true,
            ),
            home: const HomeScreen(), // Меняем на HomeScreen
        );
    }
}