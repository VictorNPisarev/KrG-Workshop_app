// lib/providers/orders_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/order_in_product.dart';
import '../models/workplace.dart';
import '../services/data_service.dart';
import '../utils/network_utils.dart';

class OrdersProvider extends ChangeNotifier
{
    // Списки заказов
    List<OrderInProduct> _currentOrders = [];
    List<OrderInProduct> _pendingOrders = [];
    
    // Текущий рабочий участок
    Workplace? _currentWorkplace;
    
    // Состояния загрузки и ошибок
    bool _isLoading = false;
    String? _error;
    bool _isInitialized = false;
        
    // Таймер для периодического обновления (опционально)
    Timer? _refreshTimer;
    
    // Геттеры
    List<OrderInProduct> get currentOrders => _currentOrders;
    List<OrderInProduct> get pendingOrders => _pendingOrders;
    Workplace? get currentWorkplace => _currentWorkplace;
    bool get isLoading => _isLoading;
    String? get error => _error;
    bool get isInitialized => _isInitialized;
    
    // Инициализация провайдера
    Future<void> initialize(String workplaceId) async
    {
        if (_isLoading) return;

        _isLoading = true;
        _error = null;
        notifyListeners();
        
        try
        {
            print('🔄 OrdersProvider.initialize: начало, workplaceId=$workplaceId');
            
            //Проверяем интернет (опционально, можно убрать если мешает)
             if (!await NetworkUtils.hasInternetConnection()) 
             {
                 throw Exception('Нет подключения к интернету');
             }

            // Загружаем рабочие места
            final workplaces = await DataService.getWorkplaces();
            print('✅ Загружено рабочих мест: ${workplaces.length}');
            
            // Находим нужное рабочее место
            final workplace = workplaces.firstWhere(
                (wp) => wp.id == workplaceId,
                orElse: () {
                    print('⚠️ Workplace $workplaceId не найден, использую первый');
                    return workplaces.isNotEmpty ? workplaces.first : Workplace.fallback();
                },
            );
            
            _currentWorkplace = workplace;
            print('✅ Текущее рабочее место: ${workplace.name}');
            
            // Загружаем заказы (пока из локальных данных)
            // TODO: Позже замените на вызов API
            await _loadOrders();
            //_currentOrders = await DataService.getOrdersForWorkplace(_currentWorkplace!.id);
            
            print('✅ Загружено заказов: ${_currentOrders.length}');

            // Запускаем периодическое обновление (каждые 30 секунд)
            _startAutoRefresh();
            
            _isInitialized = true;
            print('✅ OrdersProvider.initialize: завершено успешно');
        }
        catch (e)
        {
            _error = 'Ошибка инициализации: $e';
            print('❌ OrdersProvider.initialize: ошибка - $e');
            
            // Используем fallback
            _useFallbackData(workplaceId);
        }
        finally
        {
            _isLoading = false;
            notifyListeners();
        }
    }

    void _useFallbackData(String workplaceId) async
    {
        print('🔄 Использую fallback данные...');
        
        // Используем DataService как fallback
        _currentOrders = await DataService.getOrdersForWorkplace(_currentWorkplace!.id);
        
        // Если есть предыдущее рабочее место, загружаем и его заказы
        if (_currentWorkplace!.previousWorkplace != null)
        {
            final previousOrders = await DataService.getOrdersForWorkplace(_currentWorkplace!.previousWorkplace!);
            _pendingOrders = previousOrders.where((order) 
                => order.status == OrderStatus.inProgress).toList();
        }
        else
        {
            _pendingOrders = [];
        }
    }

    // Основная загрузка заказов
    Future<void> _loadOrders() async
    {
        if (_currentWorkplace == null) return;
        
        try
        {
            print('🔄 Загрузка заказов для текущего участка...');
            
            // 1. Загружаем текущие заказы (для текущего рабочего места)
            _currentOrders = await DataService.getOrdersForWorkplace(_currentWorkplace!.id);
            print('✅ Текущих заказов: ${_currentOrders.length}');
            
            // 2. Если есть предыдущее рабочее место, загружаем ожидающие заказы
            if (_currentWorkplace!.previousWorkplace != null)
            {
                print('🔄 Загрузка ожидающих заказов с предыдущего участка: ${_currentWorkplace!.previousWorkplace}');
                
                // Загружаем заказы с предыдущего рабочего места
                _pendingOrders = await DataService.getOrdersForWorkplace(_currentWorkplace!.previousWorkplace!);
                
                /*final previousOrders = await DataService.getOrdersForWorkplace(_currentWorkplace!.previousWorkplace!);
                // Фильтруем только те, которые в работе (inProgress) на предыдущем участке
                _pendingOrders = previousOrders.where((order) 
                    => order.status == OrderStatus.inProgress).toList();*/
                
                print('✅ Ожидающих заказов: ${_pendingOrders.length}');
            }
            else
            {
                _pendingOrders = [];
                print('ℹ️ Нет предыдущего рабочего места, ожидающие заказы не загружаются');
            }
        }
        catch (e)
        {
            _error = 'Ошибка загрузки заказов: ${e.toString()}';
            print('❌ Ошибка при загрузке заказов: $e');
        }
    }

    // Получить заказ по ID (ищет в обоих списках)
    OrderInProduct? getOrderById(String id)
    {
        try
        {
            return _currentOrders.firstWhere((order) => order.id == id);
        }
        catch (_)
        {
            try
            {
                return _pendingOrders.firstWhere((order) => order.id == id);
            }
            catch (_)
            {
                return null;
            }
        }
    }
    
    // Взять заказ в работу
    Future<void> takeOrderToWork(OrderInProduct order) async
    {
        if (_currentWorkplace == null) return;
        
        _isLoading = true;
        notifyListeners();
        
        try
        {
            // Отправляем запрос на сервер
            final success = await DataService.updateOrderStatus(
                orderId: order.id,
                workplaceId: _currentWorkplace!.id, // Меняем на текущее рабочее место
                status: OrderStatus.inProgress,
                comment: 'Взято в работу на участке ${_currentWorkplace!.name}',
            );
            
            if (success)
            {
                // Локально обновляем заказ
                final updatedOrder = order.copyWith(
                    status: OrderStatus.inProgress,
                    changeDate: DateTime.now(),
                    workplaceId: _currentWorkplace!.id, // Важно: меняем workplaceId!
                );
                
                _updateOrderInLists(updatedOrder);
                
                print('✅ Заказ ${order.orderNumber} взят в работу на участке ${_currentWorkplace!.name}');
            }
            else
            {
                _error = 'Не удалось обновить статус заказа на сервере';
            }
        }
        catch (e)
        {
            _error = 'Ошибка сети: ${e.toString()}';
        }
        finally
        {
            _isLoading = false;
            notifyListeners();
        }
    }

    // Завершить заказ
    Future<void> completeOrder(OrderInProduct order) async
    {
        if (_currentWorkplace == null) return;
        
        _isLoading = true;
        notifyListeners();
        
        try
        {
            // Отправляем запрос на сервер
            final success = await DataService.updateOrderStatus(
                orderId: order.id,
                workplaceId: _currentWorkplace!.id,
                status: OrderStatus.completed,
                comment: 'Завершено на участке ${_currentWorkplace!.name}',
            );
            
            if (success)
            {
                // Локально обновляем заказ
                final updatedOrder = order.copyWith(
                    status: OrderStatus.completed,
                    changeDate: DateTime.now(),
                );
                
                _updateOrderInLists(updatedOrder);
            }
            else
            {
                _error = 'Не удалось обновить статус заказа на сервере';
            }
        }
        catch (e)
        {
            _error = 'Ошибка сети: ${e.toString()}';
        }
        finally
        {
            _isLoading = false;
            notifyListeners();
        }
    }
    
    // Обновление заказов в списках (после изменений)
    void _updateOrderInLists(OrderInProduct updatedOrder)
    {
        // Удаляем из обоих списков
        _currentOrders.removeWhere((order) => order.id == updatedOrder.id);
        _pendingOrders.removeWhere((order) => order.id == updatedOrder.id);
        
        // Добавляем в нужный список в зависимости от нового статуса и рабочего места
        if (updatedOrder.status == OrderStatus.inProgress)
        {
            // Если заказ теперь на текущем рабочем месте - в текущие
            if (updatedOrder.workplaceId == _currentWorkplace?.id)
            {
                _currentOrders.add(updatedOrder);
            }
            // Если заказ на предыдущем рабочем месте - в ожидающие
            else if (updatedOrder.workplaceId == _currentWorkplace?.previousWorkplace)
            {
                _pendingOrders.add(updatedOrder);
            }
        }
        else if (updatedOrder.status == OrderStatus.pending)
        {
            // Pending заказы обычно находятся на предыдущем участке
            if (updatedOrder.workplaceId == _currentWorkplace?.previousWorkplace)
            {
                _pendingOrders.add(updatedOrder);
            }
        }
        // Завершенные заказы не показываем в списках
        
        // Сортируем по дате изменения (новые сверху)
        _currentOrders.sort((a, b) => b.changeDate.compareTo(a.changeDate));
        _pendingOrders.sort((a, b) => b.changeDate.compareTo(a.changeDate));
        
        notifyListeners();
    }

    // Ручное обновление (pull-to-refresh)
    Future<void> refreshOrders() async
    {
        _isLoading = true;
        notifyListeners();
        
        try
        {
            await _loadOrders();
            _error = null;
        }
        catch (e)
        {
            _error = 'Ошибка обновления: ${e.toString()}';
        }
        finally
        {
            _isLoading = false;
            notifyListeners();
        }
    }
    
    // Периодическое автообновление
    void _startAutoRefresh()
    {
        // Останавливаем предыдущий таймер, если был
        _refreshTimer?.cancel();
        
        // Запускаем новый (обновляем каждые 30 секунд)
        _refreshTimer = Timer.periodic(const Duration(minutes: 30), (timer) 
        {
            _loadOrders();
            notifyListeners();
        });
    }
    
    // Остановить автообновление
    void stopAutoRefresh()
    {
        _refreshTimer?.cancel();
        _refreshTimer = null;
    }
    
    // Сброс ошибки
    void clearError()
    {
        _error = null;
        notifyListeners();
    }
    
    // Метод для смены рабочего участка
    Future<void> changeWorkplace(String workplaceId) async
    {
        _isLoading = true;
        notifyListeners();
        
        try
        {
            // Останавливаем автообновление для текущего участка
            stopAutoRefresh();
            
            // Очищаем текущие данные
            _currentOrders.clear();
            _pendingOrders.clear();
            _currentWorkplace = null;
            
            // Инициализируем новый участок
            await initialize(workplaceId);
        }
        catch (e)
        {
            _error = 'Ошибка смены участка: ${e.toString()}';
        }
        finally
        {
            _isLoading = false;
            notifyListeners();
        }
    }
    
    // Получить следующий участок (если есть)
    String? getNextWorkplaceId()
    {
        return _currentWorkplace?.nextWorkPlace;
    }
    
    // Получить предыдущий участок (если есть)
    String? getPreviousWorkplaceId()
    {
        return _currentWorkplace?.previousWorkplace;
    }

    void clearData()
    {
        _currentOrders.clear();
        _pendingOrders.clear();
        _currentWorkplace = null;
        _isInitialized = false;
        _isLoading = false;
        _error = null;
        
        notifyListeners();
        print('🗑️ OrdersProvider: данные очищены');
    }
    
    // Ручное обновление всех заказов (и текущих и ожидающих)
    Future<void> refreshAllOrders() async
    {
        _isLoading = true;
        notifyListeners();
        
        try
        {
            await _loadOrders();
            _error = null;
        }
        catch (e)
        {
            _error = 'Ошибка обновления: ${e.toString()}';
        }
        finally
        {
            _isLoading = false;
            notifyListeners();
        }
    }

    // Очистка ресурсов при закрытии приложения
    @override
    void dispose()
    {
        stopAutoRefresh();
        super.dispose();
    }
}