// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/config_service.dart';
import '../services/data_service.dart';

class SettingsScreen extends StatefulWidget
{
	const SettingsScreen({super.key});

	@override
	State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
{
	int _selectedIndex = 0;
	bool _isLoading = false;

	@override
	void initState()
	{
		super.initState();
		_loadCurrentConfig();
	}

	Future<void> _loadCurrentConfig() async
	{
		final config = await ConfigService.getCurrentConfig();
		setState(()
		{
			_selectedIndex = AppConfig.all.indexWhere((c) => c.name == config.name);
			if (_selectedIndex == -1) _selectedIndex = 0;
		});
	}

	Future<void> _saveConfig(int index) async
	{
		setState(() => _isLoading = true);

		try
		{
			await ConfigService.setCurrentConfig(index);
			await DataService.refreshApiUrl();

			if (mounted)
			{
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text('Сервер переключён на: ${AppConfig.all[index].name}'),
						backgroundColor: Colors.green,
					),
				);
				Navigator.pop(context);
			}
		}
		catch (e)
		{
			if (mounted)
			{
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text('Ошибка: $e'),
						backgroundColor: Colors.red,
					),
				);
			}
		}
		finally
		{
			if (mounted) setState(() => _isLoading = false);
		}
	}

	@override
	Widget build(BuildContext context)
	{
		return Scaffold(
			appBar: AppBar(
				title: const Text('Настройки сервера'),
				centerTitle: true,
			),
			body: _isLoading
					? const Center(child: CircularProgressIndicator())
					: ListView(
							children: [
								const Padding(
									padding: EdgeInsets.all(16),
									child: Text(
										'Выбор API сервера:',
										style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
									),
								),
								...AppConfig.all.asMap().entries.map((entry)
								{
									final index = entry.key;
									final config = entry.value;
									return RadioListTile<int>(
										title: Text(config.name),
										subtitle: Text(
											config.apiUrl,
											style: const TextStyle(fontSize: 12, color: Colors.grey),
										),
										value: index,
										groupValue: _selectedIndex,
										onChanged: (value)
										{
											if (value != null)
											{
												setState(() => _selectedIndex = value);
												_saveConfig(value);
											}
										},
									);
								}),
								const Divider(),
								Padding(
									padding: const EdgeInsets.all(16),
									child: Text(
										'Текущий режим: ${AppConfig.all[_selectedIndex].isProduction ? "PRODUCTION" : "DEVELOPMENT"}',
										style: TextStyle(
											fontSize: 14,
											color: AppConfig.all[_selectedIndex].isProduction
													? Colors.green
													: Colors.orange,
											fontWeight: FontWeight.bold,
										),
									),
								),
								if (AppConfig.all[_selectedIndex].isProduction)
									Container(
										margin: const EdgeInsets.all(16),
										padding: const EdgeInsets.all(12),
										decoration: BoxDecoration(
											color: Colors.red.shade50,
											borderRadius: BorderRadius.circular(8),
											border: Border.all(color: Colors.red.shade200),
										),
										child: const Row(
											children: [
												Icon(Icons.warning, color: Colors.red),
												SizedBox(width: 8),
												Expanded(
													child: Text(
														'Внимание! Продакшен сервер используется для реальной работы.',
														style: TextStyle(color: Colors.red),
													),
												),
											],
										),
									),
							],
						),
		);
	}
}