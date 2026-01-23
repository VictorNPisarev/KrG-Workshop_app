// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/workplace.dart';
import '../services/data_service.dart';

class AuthProvider extends ChangeNotifier
{
    User? _currentUser;
    Workplace? _currentWorkplace;
    List<Workplace> _availableWorkplaces = [];
    bool _isLoading = false;
    String? _error;
    bool _isInitialized = false;
     
    // Ключи для SharedPreferences
    static const String _keyUserEmail = 'user_email';
    String get keyUserEmail => _keyUserEmail;
    static const String _keyWorkplaceId = 'workplace_id';
    String get keyWorkplaceId => _keyWorkplaceId;
    static const String _keyRememberMe = 'remember_me';
    String get keyRememberMe => _keyRememberMe;
    
    User? get currentUser => _currentUser;
    Workplace? get currentWorkplace => _currentWorkplace;
    List<Workplace> get availableWorkplaces => _availableWorkplaces;
    bool get isLoading => _isLoading;
    String? get error => _error;
    bool get isAuthenticated => _currentUser != null;    
    bool get isInitialized => _isInitialized;

    // Инициализация при запуске приложения
    Future<void> initialize() async
    {
        if (_isLoading) return;
        
        _isLoading = true;
        _error = null;
        notifyListeners();
        
        print('🔄 AuthProvider.initialize: НАЧАЛО');
        
        try
        {
            // 1. СНАЧАЛА просто устанавливаем, что инициализация прошла
            print('✅ Пропускаем загрузку данных для теста');
            
            await Future.delayed(const Duration(seconds: 2)); // Имитация загрузки
            
            // 2. Помечаем как инициализированное
            _isInitialized = true;
            
            print('✅ AuthProvider.initialize: ЗАВЕРШЕНО (упрощенная версия)');
        }
        catch (e)
        {
            _error = 'Ошибка: $e';
            print('❌ Ошибка: $e');
        }
        finally
        {
            _isLoading = false;
            notifyListeners();
        }
    }

    // Восстановление сессии из SharedPreferences
    Future<void> _restoreSession() async
    {
        try
        {
            final prefs = await SharedPreferences.getInstance();
            final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
            
            if (!rememberMe)
            {
                print('ℹ️ Remember me отключен, сессия не восстанавливается');
                return;
            }
            
            final savedEmail = prefs.getString(_keyUserEmail);
            if (savedEmail == null || savedEmail.isEmpty)
            {
                print('ℹ️ Нет сохраненного email');
                return;
            }
            
            print('🔄 Восстановление сессии для email: $savedEmail');
            
            // Ищем пользователя
            final user = await DataService.getUserByEmail(savedEmail);

            if (user == null)
            {
                throw Exception('Email не найден');
            }            
            _currentUser = user;

            print('✅ Пользователь восстановлен: ${user.name}');
            
            // Загружаем рабочие места пользователя
            await _loadUserWorkplaces(user.id);
            
            // Восстанавливаем выбранное рабочее место
            final savedWorkplaceId = prefs.getString(_keyWorkplaceId);
            if (savedWorkplaceId != null && savedWorkplaceId.isNotEmpty)
            {
                final workplace = _availableWorkplaces.firstWhere(
                    (wp) => wp.id == savedWorkplaceId,
                    orElse: () => _availableWorkplaces.firstOrNull ?? Workplace.fallback(),
                );
                
                await selectWorkplace(workplace);
                print('✅ Рабочее место восстановлено: ${workplace.name}');
            }
            else if (_availableWorkplaces.length == 1)
            {
                // Если только одно рабочее место - выбираем автоматически
                await selectWorkplace(_availableWorkplaces.first);
            }
            
            print('✅ Сессия успешно восстановлена');
        }
        catch (e)
        {
            print('❌ Ошибка восстановления сессии: $e');
            // При ошибке очищаем сохраненные данные
            await _clearSession();
        }
    }

    // Вход пользователя (по email или выбором)
    Future<void> loginWithEmail(String email, {bool rememberMe = true}) async
    {
        _isLoading = true;
        _error = null;
        notifyListeners();
        
        try
        {
            print('🔑 Вход пользователя: $email, rememberMe: $rememberMe');
            
            // Ищем пользователя
            final user = await DataService.getUserByEmail(email);

            if (user == null)
            {
                throw Exception('Email не найден');
            }            
            _currentUser = user;

            print('✅ Пользователь найден: ${user.name} (ID: ${user.id})');
            
            // Загружаем доступные рабочие места пользователя
            await _loadUserWorkplaces(user.id);
            
            // Сохраняем сессию если нужно
            if (rememberMe)
            {
                await _saveSession(email);
            }
            else
            {
                await _clearSession();
            }
 
            // Если только одно рабочее место - выбираем автоматически
            if (_availableWorkplaces.length == 1)
            {
                await selectWorkplace(_availableWorkplaces.first);
            }
            else if (_availableWorkplaces.isEmpty)
            {
                throw Exception('У пользователя нет доступных рабочих мест');
            }
            
            print('✅ Вход выполнен успешно');
        }
        catch (e)
        {
            _error = 'Ошибка входа: ${e.toString()}';
            print('❌ Ошибка входа: $e');
            
            // Сбрасываем состояние
            _currentUser = null;
            _currentWorkplace = null;
            _availableWorkplaces.clear();
            
            rethrow;
        }
        finally
        {
            _isLoading = false;
            notifyListeners();
        }
    }

    // Загрузка рабочих мест пользователя
    Future<void> _loadUserWorkplaces(String userId) async
    {
        try
        {
            final workplaces = await DataService.getUserWorkplaces(userId);
            
            _availableWorkplaces = workplaces;
            
            print('✅ Доступные рабочие места: ${_availableWorkplaces.length}');
        }
        catch (e)
        {
            throw Exception('Не удалось загрузить рабочие места: $e');
        }
    }
    
    // Выбор рабочего места
    Future<void> selectWorkplace(Workplace workplace) async
    {
        _currentWorkplace = workplace;
        print('🎯 Выбрано рабочее место: ${workplace.name}');
        
        // Сохраняем выбор
        await _saveWorkplaceSelection(workplace.id);
        
        notifyListeners();
    }
    
    // Переключение между рабочими местами
    Future<void> switchWorkplace(String workplaceId) async
    {
        final workplace = _availableWorkplaces.firstWhere(
            (wp) => wp.id == workplaceId,
            orElse: () => throw Exception('Рабочее место недоступно'),
        );
        
        await selectWorkplace(workplace);
    }
    
    // Выход с опцией "запомнить меня"
    Future<void> logout({bool keepSession = false}) async
    {
        _currentUser = null;
        _currentWorkplace = null;
        _availableWorkplaces.clear();
        
        if (!keepSession)
        {
            await _clearSession();
        }
        
        print('👋 Выход выполнен');
        notifyListeners();
    }
    
    // Сохранение сессии в SharedPreferences
    Future<void> _saveSession(String email) async
    {
        try
        {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_keyUserEmail, email);
            await prefs.setBool(_keyRememberMe, true);
            print('💾 Сессия сохранена для email: $email');
        }
        catch (e)
        {
            print('❌ Ошибка сохранения сессии: $e');
        }
    }
    
    // Сохранение выбора рабочего места
    Future<void> _saveWorkplaceSelection(String workplaceId) async
    {
        try
        {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_keyWorkplaceId, workplaceId);
            print('💾 Сохранен выбор рабочего места: $workplaceId');
        }
        catch (e)
        {
            print('❌ Ошибка сохранения рабочего места: $e');
        }
    }

    // Очистка сохраненной сессии
    Future<void> _clearSession() async
    {
        try
        {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_keyUserEmail);
            await prefs.remove(_keyWorkplaceId);
            await prefs.remove(_keyRememberMe);
            print('🗑️ Сессия очищена');
        }
        catch (e)
        {
            print('❌ Ошибка очистки сессии: $e');
        }
    }
}