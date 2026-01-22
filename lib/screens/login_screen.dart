import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/device_auth_service.dart';

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
    
    @override
    void initState()
    {
        super.initState();
        _checkSavedEmail();
    }
    
    // Проверяем сохраненный email
    Future<void> _checkSavedEmail() async
    {
        final authProvider = context.read<AuthProvider>();
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Автоматически заполняем email если есть в сессии
        // (сессия уже восстановлена в auth_provider)
    }
    
    @override
    Widget build(BuildContext context)
    {
        return Scaffold(
            appBar: AppBar(title: const Text('Вход')),
            body: Padding(
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
                            
                            // Кнопка для тестирования (можно убрать в продакшене)
                            /*if (kDebugMode)
                                SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                        icon: const Icon(Icons.developer_mode),
                                        label: const Text('Тестовый пользователь'),
                                        onPressed: () {
                                            _emailController.text = 'test@example.com';
                                            _login();
                                        },
                                    ),
                                ),*/
                        ],
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
        }
        catch (e)
        {
            if (!mounted) return;
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