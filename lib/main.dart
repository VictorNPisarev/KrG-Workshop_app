import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/orders_provider.dart';
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
                ChangeNotifierProvider(
                    create: (_) => OrdersProvider(),
                ),
            ],
            child: MaterialApp(
                title: 'Workshop App',
                theme: ThemeData(
                    primarySwatch: Colors.blue,
                    useMaterial3: true,
                ),
                home: const HomeScreen(),
            ),
        );
    }
}