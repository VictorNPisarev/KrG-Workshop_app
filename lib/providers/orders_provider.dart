// lib/providers/orders_provider.dart
import 'dart:async';

import 'package:flutter/material.dart';
import '../models/orderInProduct.dart';
import '../models/workplace.dart';
import '../services/data_service.dart';

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
    
    // Таймер для периодического обновления (опционально)
    Timer? _refreshTimer;
    
    // Геттеры
    List<OrderInProduct> get currentOrders => _currentOrders;
    List<OrderInProduct> get pendingOrders => _pendingOrders;
    Workplace? get currentWorkplace => _currentWorkplace;
    bool get isLoading => _isLoading;
    String? get error => _error;
    
    // Инициализация провайдера
    Future<void> initialize(String workplaceId) async
    {
        _isLoading = true;
        _error = null;
        notifyListeners();
        
        try
        {
            // Загружаем рабочие места
            final workplaces = await DataService.getWorkplaces();
            
            // Находим нужное рабочее место
            final workplace = workplaces.firstWhere(
                (wp) => wp.id == workplaceId,
                orElse: () => throw Exception('Участок с ID $workplaceId не найден'),
            );
            
            _currentWorkplace = workplace;
            
            // Загружаем заказы для этого участка
            await _loadOrders();
            
            // Запускаем периодическое обновление (каждые 30 секунд)
            _startAutoRefresh();
        }
        catch (e)
        {
            _error = 'Ошибка инициализации: ${e.toString()}';
            rethrow;
        }
        finally
        {
            _isLoading = false;
            notifyListeners();
        }
    }
    
    // Основная загрузка заказов
    Future<void> _loadOrders() async
    {
        if (_currentWorkplace == null) return;
        
        try
        {
            // Получаем все заказы для текущего участка
            final allOrders = await DataService.getOrdersForWorkplace(_currentWorkplace!.id);
            
            // Фильтруем текущие заказы (статус "в работе" и workplaceId совпадает)
            _currentOrders = allOrders.where((order) 
                => order.workplaceId == _currentWorkplace!.id 
                && order.status == OrderStatus.inProgress).toList();
            
            // Фильтруем ожидающие заказы (с предыдущего участка)
            if (_currentWorkplace!.previousWorkPlace != null)
            {
                _pendingOrders = allOrders.where((order) 
                    => order.workplaceId == _currentWorkplace!.previousWorkPlace 
                    && order.status == OrderStatus.pending).toList();
            }
            else
            {
                _pendingOrders = [];
            }
        }
        catch (e)
        {
            _error = 'Ошибка загрузки заказов: ${e.toString()}';
            // Можно залогировать или показать уведомление
            print('Ошибка при загрузке заказов: $e');
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
                workplaceId: _currentWorkplace!.id,
                status: OrderStatus.inProgress,
                comment: 'Взято в работу на участке ${_currentWorkplace!.name}',
            );
            
            if (success)
            {
                // Локально обновляем заказ
                final updatedOrder = order.copyWith(
                    status: OrderStatus.inProgress,
                    changeDate: DateTime.now(),
                    workplaceId: _currentWorkplace!.id,
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
        
        // Добавляем в нужный список в зависимости от нового статуса
        if (updatedOrder.status == OrderStatus.inProgress)
        {
            _currentOrders.add(updatedOrder);
        }
        else if (updatedOrder.status == OrderStatus.pending)
        {
            _pendingOrders.add(updatedOrder);
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
        _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) 
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
        return _currentWorkplace?.previousWorkPlace;
    }
    
    // Очистка ресурсов при закрытии приложения
    @override
    void dispose()
    {
        stopAutoRefresh();
        super.dispose();
    }
}