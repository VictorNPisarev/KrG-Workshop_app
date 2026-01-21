// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
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
    
    User? get currentUser => _currentUser;
    Workplace? get currentWorkplace => _currentWorkplace;
    List<Workplace> get availableWorkplaces => _availableWorkplaces;
    bool get isLoading => _isLoading;
    String? get error => _error;
    bool get isAuthenticated => _currentUser != null;
    
    // Инициализация при запуске приложения
    Future<void> initialize() async
    {
        _isLoading = true;
        notifyListeners();
        
        try
        {
            print('🔄 AuthProvider: начальная инициализация');
            
            // 1. Загружаем всех пользователей
            final users = await DataService.getUsers();
            print('✅ Загружено пользователей: ${users.length}');
            
            // 2. Загружаем связи пользователь-рабочее место
            //final userWorkplaces = await DataService.getUserWorkplaces();
            //print('✅ Загружено связей: ${userWorkplaces.length}');
            
            // 3. Загружаем рабочие места
            final workplaces = await DataService.getWorkplaces();
            print('✅ Загружено рабочих мест: ${workplaces.length}');
            
            // 4. Здесь могла бы быть логика восстановления сессии
            // Например, из локального хранилища
            
            print('✅ AuthProvider: инициализация завершена');
        }
        catch (e)
        {
            _error = 'Ошибка инициализации: $e';
            print('❌ AuthProvider: ошибка инициализации - $e');
        }
        finally
        {
            _isLoading = false;
            notifyListeners();
        }
    }
    
    // Вход пользователя (по email или выбором)
    Future<void> loginWithEmail(String email) async
    {
        _isLoading = true;
        _error = null;
        notifyListeners();
        
        try
        {
            print('🔑 Вход пользователя: $email');
            
            // 1. Загружаем пользователей
            final users = await DataService.getUsers();
            print('📊 Всего пользователей в системе: ${users.length}');
            print('📋 Список email: ${users.map((u) => u.email).toList()}');
            
            // 2. Ищем пользователя
            final user = users.firstWhere(
                (u) => u.email.toLowerCase() == email.toLowerCase(),
                orElse: () => throw Exception('Пользователь с email $email не найден'),
            );
            
            _currentUser = user;
            print('✅ Пользователь найден: ${user.name} (ID: ${user.id})');
            
            // 3. Загружаем доступные рабочие места пользователя
            await _loadUserWorkplaces(user.id);
            
            // 4. Если только одно рабочее место - выбираем автоматически
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
        
        // Сохраняем выбор в локальное хранилище
        await _saveSession();
        
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
    
    // Выход
    Future<void> logout() async
    {
        _currentUser = null;
        _currentWorkplace = null;
        _availableWorkplaces.clear();
        
        // Очищаем локальное хранилище
        await _clearSession();
        
        print('👋 Выход выполнен');
        notifyListeners();
    }
    
    // Сохранение сессии (для быстрого входа)
    Future<void> _saveSession() async
    {
        // Здесь можно использовать shared_preferences или Hive
        // Пока просто логируем
        print('💾 Сохранение сессии...');
    }
    
    Future<void> _clearSession() async
    {
        print('🗑️ Очистка сессии...');
    }
}