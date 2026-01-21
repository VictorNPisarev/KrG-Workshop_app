import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

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
    String? _error;
    
    @override
    Widget build(BuildContext context)
    {
        return Scaffold(
            appBar: AppBar(title: const Text('Вход')),
            body: Padding(
                padding: const EdgeInsets.all(24),
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
                            Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                            ),
                        
                        TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
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
                    ],
                ),
            ),
        );
    }
    
    Future<void> _login() async
    {
        if (_emailController.text.isEmpty)
        {
            if (!mounted) return;
            setState(() => _error = 'Введите email');
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
            await authProvider.loginWithEmail(_emailController.text.trim());
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