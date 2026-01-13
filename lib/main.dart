import 'package:flutter/material.dart';

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
            home: const PlaceholderScreen(),
        );
    }
}

class PlaceholderScreen extends StatelessWidget
{
    const PlaceholderScreen({super.key});

    @override
    Widget build(BuildContext context)
    {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Workshop App'),
            ),
            body: const Center(
                child: Text('Приложение для производственных участков'),
            ),
        );
    }
}