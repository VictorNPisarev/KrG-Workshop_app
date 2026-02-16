import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/order_in_product.dart';
import '../models/workplace.dart';
import '../services/data_service.dart';
import '../utils/network_utils.dart';
import 'auth_provider.dart';

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

  // Таймер для периодического обновления
  Timer? _refreshTimer;

  // Геттеры
  List<OrderInProduct> get currentOrders => _currentOrders;
  List<OrderInProduct> get pendingOrders => _pendingOrders;
  Workplace? get currentWorkplace => _currentWorkplace;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Инициализация провайдера
  Future<void> initialize(String workplaceId, {Workplace? workplace, List<Workplace>? availableWorkplaces}) async 
  {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try 
    {
      print('🔄 OrdersProvider.initialize: начало, workplaceId=$workplaceId');

      // Проверяем интернет
      if (!await NetworkUtils.hasInternetConnection()) 
      {
        throw Exception('Нет подключения к интернету');
      }

      if (workplace != null)
      {
          _currentWorkplace = workplace;
          print('✅ Получил рабочее место из AuthAdapter: ${_currentWorkplace!.name}');
      }
      else if (availableWorkplaces != null && availableWorkplaces.isNotEmpty) 
      {
          // Используем переданный список
          _currentWorkplace = availableWorkplaces.firstWhere(
            (wp) => wp.id == workplaceId,
            orElse: () => Workplace.fallback(),
          );
           print('✅ Получил рабочее место из availableWorkplaces: ${_currentWorkplace!.name}');
       }
      else
      {
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
      }

      print('✅ Текущее рабочее место: ${_currentWorkplace!.name}');

      // Загружаем заказы параллельно
      await _loadOrdersParallel();

      // Запускаем периодическое обновление (каждые 5 минут)
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Параллельная загрузка заказов
Future<void> _loadOrdersParallel() async 
{
  if (_currentWorkplace == null) return;

  try 
  {
    print('🔄 Загрузка заказов для ${_currentWorkplace!.name}');
    
    // 1. Текущие заказы
    final currentFuture = DataService.getOrdersForWorkplace(
      _currentWorkplace!.id, 
      true
    );
    
    // 2. Ожидающие заказы - СО ВСЕХ возможных предыдущих участков
    final List<Future<List<OrderInProduct>>> pendingFutures = [];

    print('   Предыдущие участки: ${_currentWorkplace!.possiblePreviousWorkplaces.length}: ');
    
    // Используем новый список possiblePreviousWorkplaces
    for (final sourceId in _currentWorkplace!.possiblePreviousWorkplaces) 
    {
      if (sourceId.isNotEmpty) 
      {
        print('${_currentWorkplace!.possiblePreviousWorkplaces}');

        pendingFutures.add(DataService.getOrdersForWorkplace(sourceId, false));
      }
    }
    
    // Если есть хотя бы один источник, загружаем
    List<List<OrderInProduct>> results;
    
    if (pendingFutures.isNotEmpty) 
    {
      final allFutures = [currentFuture, ...pendingFutures];
      results = await Future.wait(allFutures);
    } 
    else 
    {
      // Если нет предыдущих участков, загружаем только текущие заказы
      results = [await currentFuture];
    }
    
    // Текущие заказы
    _currentOrders = results[0];
    
    _currentOrders.forEach((order) => order.setStatusByWorkplace(_currentWorkplace!.id));
    
    _currentOrders = _currentOrders.where((order) => !order.operations.isCompleted).toList();
    
    // Ожидающие заказы - объединяем результаты со всех источников
    _pendingOrders = [];

    for (int i = 1; i < results.length; i++) 
    {
      _pendingOrders.addAll(results[i]);

      print('i = $i, В ожидании: ${_pendingOrders.length}');
    }
    
    // Убираем дубликаты (один заказ может быть в нескольких источниках)
    final uniqueOrders = <String, OrderInProduct>{};
    
    for (final order in _pendingOrders) 
    {
      if (!uniqueOrders.containsKey(order.id)) 
      {
        uniqueOrders[order.id] = order;
      }
    }
    _pendingOrders = uniqueOrders.values.toList();
    
    _pendingOrders.forEach((order) => order.status = OrderStatus.pending);
    
    sortOrders();
    
    print('✅ Загружено: ${_currentOrders.length} текущих, '
          '${_pendingOrders.length} ожидающих (из ${_currentWorkplace!.possiblePreviousWorkplaces.length} источников)');
  } 
  catch (e) 
  {
    _error = 'Ошибка загрузки заказов: ${e.toString()}';
    print('❌ Ошибка: $e');
    rethrow;
  }
}
  void sortOrders() 
  {
    _currentOrders.sort((a, b) => a.readyDate.compareTo(b.readyDate));
    _pendingOrders.sort((a, b) => a.readyDate.compareTo(b.readyDate));
  }

  void _useFallbackData(String workplaceId) async {
    print('🔄 Использую fallback данные...');

    // Используем DataService как fallback
    _currentOrders = await DataService.getOrdersForWorkplace(_currentWorkplace!.id);

    // Если есть предыдущее рабочее место, загружаем и его заказы
    if (_currentWorkplace!.previousWorkplace != null) {
      _pendingOrders = await DataService.getOrdersForWorkplace(_currentWorkplace!.previousWorkplace!);
    } else {
      _pendingOrders = [];
    }
  }

  // Получить заказ по ID
  OrderInProduct? getOrderById(String id) {
    try {
      return _currentOrders.firstWhere((order) => order.id == id);
    } catch (_) {
      try {
        return _pendingOrders.firstWhere((order) => order.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  // Взять заказ в работу (оптимистичное обновление)
  Future<void> takeOrderToWork(OrderInProduct order, String userId) async {
    if (_currentWorkplace == null) return;

    // Немедленно обновляем локально
    final updatedOrder = order.copyWith(
      status: OrderStatus.inProgress,
      changeDate: DateTime.now(),
      workplaceId: _currentWorkplace!.id,
    );

    _updateOrderInLists(updatedOrder);
    notifyListeners();

    // Показываем уведомление
    _showSuccessNotification('Заказ ${order.orderNumber} взят в работу');

    // Отправляем на сервер в фоне
    _sendUpdateToServer(order, OrderStatus.inProgress, userId);
  }

  // Завершить заказ (оптимистичное обновление)
  Future<void> completeOrder(OrderInProduct order, String userId) async 
  {
    if (_currentWorkplace == null) return;

    // Немедленно обновляем локально
    final updatedOrder = order.copyWith(
      status: OrderStatus.completed,
      changeDate: DateTime.now(),
    );

    _updateOrderInLists(updatedOrder);
    notifyListeners();

    // Показываем уведомление
    _showSuccessNotification('Заказ ${order.orderNumber} завершен');

    // Отправляем на сервер в фоне
    _sendUpdateToServer(order, OrderStatus.completed, userId);
  }

  // Фоновая отправка на сервер
  Future<void> _sendUpdateToServer(OrderInProduct order, OrderStatus status, String? userId) async 
  {
    try 
    {  
      final response = await DataService.updateOrderStatus(
        orderId: order.id,
        workplaceId: _currentWorkplace!.id,
        userId: userId,
        status: status,
        comment: 'Завершен на участке ${_currentWorkplace!.name}',
      );

      if (response['success'] != true) {
        print('⚠️ Сервер не подтвердил обновление, но данные обновлены локально');
      }
    } catch (e) {
      print('⚠️ Ошибка фоновой синхронизации: $e');
      // Можно добавить в очередь повторных попыток
    }
  }

  // Вспомогательные методы для уведомлений
  void _showSuccessNotification(String message) {
    print('✅ $message');
  }

  void _showErrorNotification(String message) {
    print('❌ $message');
  }

  // Обновление заказов в списках
  void _updateOrderInLists(OrderInProduct updatedOrder) 
  {
    // Удаляем из обоих списков
    _currentOrders.removeWhere((order) => order.id == updatedOrder.id);
    _pendingOrders.removeWhere((order) => order.id == updatedOrder.id);

    // Добавляем в нужный список
    if (updatedOrder.status == OrderStatus.inProgress &&
        updatedOrder.workplaceId == _currentWorkplace?.id) 
    {
      _currentOrders.add(updatedOrder);
    } 
    else if (updatedOrder.status == OrderStatus.pending &&
        updatedOrder.workplaceId == _currentWorkplace?.previousWorkplace) 
    {
      _pendingOrders.add(updatedOrder);
    }

    // Сортируем
    sortOrders();

    notifyListeners();
  }

  // Ручное обновление
  Future<void> refreshOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadOrdersParallel();
      _error = null;
    } catch (e) {
      _error = 'Ошибка обновления: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Периодическое автообновление
  void _startAutoRefresh() 
  {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _loadOrdersParallel();
      notifyListeners();
    });
  }

  // Остановить автообновление
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // Сброс ошибки
  void clearError() {
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
      // Останавливаем автообновление
      stopAutoRefresh();

      // Очищаем текущие данные
      _currentOrders.clear();
      _pendingOrders.clear();
      _currentWorkplace = null;

      // Очищаем кэш перед сменой участка
      DataService.clearCache();

      // Инициализируем новый участок
      await initialize(workplaceId);
    } catch (e) {
      _error = 'Ошибка смены участка: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _currentOrders.clear();
    _pendingOrders.clear();
    _currentWorkplace = null;
    _isInitialized = false;
    _isLoading = false;
    _error = null;
    
    stopAutoRefresh();
    
    notifyListeners();
    print('🗑️ OrdersProvider: данные очищены');
  }

  Future<void> refreshAllOrders() async {
    _isLoading = true;
    notifyListeners();

    try 
    {
      await _loadOrdersParallel();
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

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}