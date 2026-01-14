import 'package:flutter/material.dart';
import '../models/orderInProduct.dart';
import '../models/workplace.dart';
import '../services/data_service.dart';

class OrdersProvider extends ChangeNotifier
{
    List<OrderInProduct> _currentOrders = [];
    List<OrderInProduct> _pendingOrders = [];
    Workplace? _currentWorkplace;
    
    // Геттеры
    List<OrderInProduct> get currentOrders => _currentOrders;
    List<OrderInProduct> get pendingOrders => _pendingOrders;
    Workplace? get currentWorkplace => _currentWorkplace;
    
    // Инициализация (вызывается при входе)
    void initialize(String workplaceId)
    {
        final workplace = DataService.getWorkplaceById(workplaceId);
        if (workplace == null)
        {
            throw Exception('Участок с ID $workplaceId не найден');
        }
        
        _currentWorkplace = workplace;
        _loadOrders();
    }
    
    // Загрузка заказов
    void _loadOrders()
    {
        if (_currentWorkplace == null) return;
        
        _currentOrders = DataService.getCurrentOrders(_currentWorkplace!.id);
        _pendingOrders = DataService.getPendingOrders(_currentWorkplace!.id);
        notifyListeners();
    }
    
    // Обновление заказа (с автоматическим перемещением между списками)
    void updateOrder(OrderInProduct updatedOrder)
    {
        // Удаляем из обоих списков
        _currentOrders.removeWhere((order) => order.id == updatedOrder.id);
        _pendingOrders.removeWhere((order) => order.id == updatedOrder.id);
        
        // Добавляем в нужный список в зависимости от статуса
        if (updatedOrder.status == OrderStatus.inProgress)
        {
            _currentOrders.add(updatedOrder);
        }
        else if (updatedOrder.status == OrderStatus.pending)
        {
            _pendingOrders.add(updatedOrder);
        }
        // completed заказы не добавляем никуда
        
        notifyListeners();
    }
    
    // Методы для конкретных действий
    void takeOrderToWork(OrderInProduct order)
    {
        final updatedOrder = order.copyWith(
            status: OrderStatus.inProgress,
            changeDate: DateTime.now(),
            workplaceId: _currentWorkplace?.id ?? order.workplaceId,
        );
        updateOrder(updatedOrder);
    }
    
    void completeOrder(OrderInProduct order)
    {
        final updatedOrder = order.copyWith(
            status: OrderStatus.completed,
            changeDate: DateTime.now(),
        );
        updateOrder(updatedOrder);
    }
    
    // Обновление списков (например, при pull-to-refresh)
    void refreshOrders()
    {
        _loadOrders();
    }

    OrderInProduct? getOrderById(String id)
    {
        // Ищем в текущих заказах
        try
        {
            return _currentOrders.firstWhere((order) => order.id == id);
        }
        catch (e)
        {
            // Ищем в ожидающих заказах
            try
            {
                return _pendingOrders.firstWhere((order) => order.id == id);
            }
            catch (e)
            {
                return null;
            }
        }
    }
}