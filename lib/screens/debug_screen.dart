// lib/screens/debug_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DebugScreen extends StatelessWidget
{
    const DebugScreen({super.key});
    
    @override
    Widget build(BuildContext context)
    {
        final authProvider = Provider.of<AuthProvider>(context);
        
        return Scaffold(
            appBar: AppBar(title: const Text('Диагностика')),
            body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    const Text(
                                        'Состояние AuthProvider',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('isLoading:', authProvider.isLoading.toString()),
                                    _buildInfoRow('isInitialized:', authProvider.isInitialized.toString()),
                                    _buildInfoRow('isAuthenticated:', authProvider.isAuthenticated.toString()),
                                    _buildInfoRow('currentUser:', authProvider.currentUser?.email ?? 'null'),
                                    _buildInfoRow('currentWorkplace:', authProvider.currentWorkplace?.name ?? 'null'),
                                    _buildInfoRow('availableWorkplaces:', authProvider.availableWorkplaces.length.toString()),
                                    _buildInfoRow('error:', authProvider.error ?? 'null'),
                                ],
                            ),
                        ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Повторить инициализацию'),
                        onPressed: () => authProvider.initialize(),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    ElevatedButton.icon(
                        icon: const Icon(Icons.bug_report),
                        label: const Text('Тест API'),
                        onPressed: () => _testApi(context),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    ElevatedButton.icon(
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Сбросить приложение'),
                        onPressed: () => _resetApp(context),
                    ),
                ],
            ),
        );
    }
    
    Widget _buildInfoRow(String label, String value)
    {
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    SizedBox(
                        width: 180,
                        child: Text(
                            label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                            ),
                        ),
                    ),
                    Expanded(
                        child: Text(
                            value,
                            style: const TextStyle(fontFamily: 'monospace'),
                        ),
                    ),
                ],
            ),
        );
    }
    
    Future<void> _testApi(BuildContext context) async
    {
        try
        {
            final response = await http.get(
                Uri.parse('https://script.google.com/macros/s/AKfycbzoDyvGU4ZHKg4oy1rGmxvxLTfnMATV21eYUzTFsj4pTxz3ii3sqw-i6fk5vElvrqBR-w/exec?action=getWorkplaces'),
            );
            
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                    title: const Text('Тест API'),
                    content: Text(
                        'Статус: ${response.statusCode}\n'
                        'Длина ответа: ${response.body.length} байт\n'
                        'Первые 200 символов:\n${response.body.substring(0, 200)}...',
                    ),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                        ),
                    ],
                ),
            );
        }
        catch (e)
        {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                    title: const Text('Ошибка API'),
                    content: Text('$e'),
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
    
    void _resetApp(BuildContext context)
    {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.logout();
    }
}