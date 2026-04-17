import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/device_auth_service.dart';
import '../utils/platform_utils.dart';
import '../services/config_service.dart';
import '../services/data_service.dart';
import '../config/app_config.dart';
import 'settings_screen.dart';

class LoginScreen extends StatefulWidget
{
	const LoginScreen({super.key});
	
	@override
	State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
{
	final _emailController = TextEditingController();
	bool _isLoading = false;
	bool _rememberMe = true;
	String? _error;
	String _currentServerName = '';
	bool _autoLoginAttempted = false;


	@override
	void initState()
	{
		super.initState();
		_loadCurrentServer();
		_checkSavedEmail();
	}

	Future<void> _loadCurrentServer() async
	{
		final config = await ConfigService.getCurrentConfig();
		if (mounted)
		{
			setState(() {
				_currentServerName = config.name;
			});
		}
	}

	// Проверяем сохраненный email
	Future<void> _checkSavedEmail() async
	{
		// Защита от повторного вызова
		if (_autoLoginAttempted) return;
		_autoLoginAttempted = true;

		final authProvider = context.read<AuthProvider>();
		
		// Пробуем получить email с устройства
		final prefs = await SharedPreferences.getInstance();
		final rememberMe = prefs.getBool(authProvider.keyRememberMe) ?? false;
			
		if (!rememberMe)
		{
			print('ℹ️ Remember me отключен, сессия не восстанавливается');
			return;
		}
			
		final savedEmail = prefs.getString(authProvider.keyUserEmail);
		if (savedEmail != null && savedEmail.isNotEmpty)
		{
			print('🔄 Восстановление сессии для email: $savedEmail');
			_emailController.text = savedEmail;
			// Показываем сообщение пользователю
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text('Найден сохраненный email: $savedEmail'),
					duration: const Duration(seconds: 1),
				),
			);
		}
		else
		{
			print('ℹ️ Нет сохраненного email');
			_autoLoginAttempted = false;

			return;
		}
			
		await _login();
	}

	// Показываем настройки по долгому нажатию
	void _showSettings()
	{
		Navigator.push(
			context,
			MaterialPageRoute(builder: (context) => const SettingsScreen()),
		).then((_) async 
		{
			// После возврата из настроек обновляем информацию о сервере
			await _loadCurrentServer();
			// Очищаем поле email, чтобы пользователь ввёл заново
			//_emailController.clear();
			setState(() 
			{
				_error = null;
			});
		});
	}
	
	@override
	Widget build(BuildContext context)
	{
		return Scaffold(
			appBar: AppBar(
				title: const Text('Вход'),
				actions: [
					// Индикатор текущего сервера
					Container(
						margin: const EdgeInsets.only(right: 16),
						padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
						decoration: BoxDecoration(
							color: _currentServerName.contains('GAS') 
								? Colors.green.shade100 
								: Colors.orange.shade100,
							borderRadius: BorderRadius.circular(12),
						),
						child: Text(
							_currentServerName,
							style: TextStyle(
								fontSize: 10,
								color: _currentServerName.contains('GAS') 
									? Colors.green.shade800 
									: Colors.orange.shade800,
							),
						),
					),
				],
			),
			body: GestureDetector(
				// Долгое нажатие для вызова настроек
				onLongPress: _showSettings,
				child: Padding(
					padding: const EdgeInsets.all(24),
					child: SingleChildScrollView(
						child: Column(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
								const Icon(Icons.account_circle, size: 80, color: Colors.blue),
								const SizedBox(height: 24),
								const Text(
									'Приложение для производственных участков',
									textAlign: TextAlign.center,
									style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
								),
								const SizedBox(height: 32),
								
								if (_error != null)
									Container(
										padding: const EdgeInsets.all(12),
										decoration: BoxDecoration(
											color: Colors.red.shade50,
											borderRadius: BorderRadius.circular(8),
											border: Border.all(color: Colors.red.shade200),
										),
										child: Row(
											children: [
												const Icon(Icons.error, color: Colors.red),
												const SizedBox(width: 8),
												Expanded(
													child: Text(
														_error!,
														style: const TextStyle(color: Colors.red),
													),
												),
											],
										),
									),
								
								if (_error != null) const SizedBox(height: 16),
								
								TextField(
									controller: _emailController,
									decoration: const InputDecoration(
										labelText: 'Email',
										hintText: 'Введите ваш email',
										prefixIcon: Icon(Icons.email),
										border: OutlineInputBorder(),
									),
									keyboardType: TextInputType.emailAddress,
									autofillHints: const [AutofillHints.email],
								),
								const SizedBox(height: 16),
								
								// Чекбокс "Запомнить меня"
								Row(
									children: [
										Checkbox(
											value: _rememberMe,
											onChanged: (value) {
												setState(() {
													_rememberMe = value ?? true;
												});
											},
										),
										const Text('Запомнить меня'),
										const Spacer(),
										// Кнопка "Использовать email устройства"
										if (!PlatformUtils.isWeb)
											TextButton.icon(
												icon: const Icon(Icons.phone_android),
												label: const Text('С устройства'),
												onPressed: () => _useDeviceEmail(context),
											),
									],
								),
								
								const SizedBox(height: 24),
								
								if (_isLoading)
									const CircularProgressIndicator()
								else
									SizedBox(
										width: double.infinity,
										child: ElevatedButton.icon(
											icon: const Icon(Icons.login),
											label: const Text('Войти'),
											onPressed: _login,
										),
									),
								
								const SizedBox(height: 16),
							],
						),
					),
				),
			),
		);
	}
	
	// Получение email с устройства (базовая реализация)
	Future<void> _useDeviceEmail(BuildContext context) async
	{
		setState(() {
			_isLoading = true;
			_error = null;
		});
		
		try
		{
			// Пробуем получить email с устройства
			final deviceEmail = await DeviceAuthService.getEmailFromGoogle();
			
			if (deviceEmail != null && deviceEmail.isNotEmpty)
			{
				_emailController.text = deviceEmail;
				
				// Автоматически пытаемся войти
				await _login();
			}
			else
			{
				// Пробуем получить через нативный канал
				final nativeEmail = await DeviceAuthService.getDeviceEmail();
				
				if (nativeEmail != null && nativeEmail.isNotEmpty)
				{
					_emailController.text = nativeEmail;
					await _login();
				}
				else
				{
					setState(() => _error = 'Не удалось получить email с устройства');
				}
			}
		}
		catch (e)
		{
			setState(() => _error = 'Ошибка: $e');
		}
		finally
		{
			if (mounted)
			{
				setState(() => _isLoading = false);
			}
		}
	}

	Future<void> _login() async
	{
		final email = _emailController.text.trim();
		
		if (email.isEmpty)
		{
			if (!mounted) return;
			setState(() => _error = 'Введите email');
			return;
		}
		
		if (!email.contains('@'))
		{
			if (!mounted) return;
			setState(() => _error = 'Введите корректный email');
			return;
		}
		
		if (!mounted) return;
		setState(()
		{
			_isLoading = true;
			_error = null;
		});
		
		try
		{
			final authProvider = context.read<AuthProvider>();
			await authProvider.loginWithEmail(email, rememberMe: _rememberMe);

			// Сброс флага при успешном входе
			_autoLoginAttempted = false;
		}
		catch (e)
		{
			if (!mounted) return;

			// При ошибке очищаю сохранённую сессию
			final authProvider = context.read<AuthProvider>();
			await authProvider.logout(keepSession: false);
			
			// Сбрасываю флаг, чтобы можно было повторить попытку
			_autoLoginAttempted = false;

			setState(() => _error = 'Ошибка: $e');
		}
		finally
		{
			if (mounted)
			{
				setState(() => _isLoading = false);
			}
		}
	}
}