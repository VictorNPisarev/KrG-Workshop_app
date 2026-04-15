// lib/screens/debug_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/config_service.dart';
import '../services/data_service.dart';
import '../config/app_config.dart';
import 'settings_screen.dart';

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

			if (context.mounted)
			{
				showDialog(
					context: context,
					builder: (context) => AlertDialog(
						title: const Text('Тест API'),
						content: Text(
							'Статус: ${response.statusCode}\n'
							'Длина ответа: ${response.body.length} байт\n'
							'Первые 200 символов:\n${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
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
		}
		catch (e)
		{
			if (context.mounted)
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
	}

	Future<void> _showSettings(BuildContext context) async
	{
		// Показываем диалог подтверждения перед входом в настройки
		final confirmed = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Настройки сервера'),
				content: const Text(
					'Переключение сервера может повлиять на работу приложения.\n'
					'Убедитесь, что вы знаете, что делаете.\n\n'
					'Продолжить?',
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context, false),
						child: const Text('Отмена'),
					),
					ElevatedButton(
						onPressed: () => Navigator.pop(context, true),
						style: ElevatedButton.styleFrom(
							backgroundColor: Colors.orange,
						),
						child: const Text('Продолжить'),
					),
				],
			),
		);

		if (confirmed == true && context.mounted)
		{
			Navigator.push(
				context,
				MaterialPageRoute(builder: (_) => const SettingsScreen()),
			);
		}
	}

	void _resetApp(BuildContext context)
	{
		final authProvider = Provider.of<AuthProvider>(context, listen: false);
		authProvider.logout();
	}
}