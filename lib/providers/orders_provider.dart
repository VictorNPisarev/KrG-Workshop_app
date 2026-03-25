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
	bool _isRefreshing = false;  // поле для индикации обновления

	// Таймер для периодического обновления
	Timer? _refreshTimer;

	// Геттеры
	List<OrderInProduct> get currentOrders => _currentOrders;
	List<OrderInProduct> get pendingOrders => _pendingOrders;
	Workplace? get currentWorkplace => _currentWorkplace;
	bool get isLoading => _isLoading;
	String? get error => _error;
	bool get isInitialized => _isInitialized;
	bool get isRefreshing => _isRefreshing;


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
		} catch (e) {
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
			print('🔄 Загрузка заказов...');

	/*		// Создаем Future для параллельного выполнения
			final futures = <Future<List<OrderInProduct>>>[
				DataService.getOrdersForWorkplace(_currentWorkplace!.id, true),
				if (_currentWorkplace!.previousWorkplace != null)
				DataService.getOrdersForWorkplace(_currentWorkplace!.id, false),
			];

			// Выполняем параллельно
			final results = await Future.wait(futures);
			
			// Текущие заказы (всегда первый результат)
			_currentOrders = results[0];
			//_currentOrders.forEach((order) => order.setStatusByWorkplace(_currentWorkplace!.id));
			//_currentOrders = _currentOrders.where((order) => !order.operations.isCompleted).toList();
			
			// Ожидающие заказы (если есть второй результат)
			_pendingOrders = results.length > 1 ? results[1] : [];
			//_pendingOrders.forEach((order) => order.status = OrderStatus.pending);
	*/
			// Делаем один запрос, который возвращает все заказы с полем "workplaceOrderStatus"
			final allOrders = await DataService.getAllOrdersForWorkplace(_currentWorkplace!.id);
			
			// Распределяем по спискам
			_currentOrders = [];
			_pendingOrders = [];
			
			for (var order in allOrders) 
			{
				// Проверяем поле workplaceOrderStatus
				if (order.status == OrderStatus.inProgress) 
				{
					_currentOrders.add(order);
				} 
				else if (order.status == OrderStatus.pending) 
				{
					_pendingOrders.add(order);
				}
			}

			
			sortOrders();
			
			print('✅ Загружено: ${_currentOrders.length} текущих, ${_pendingOrders.length} ожидающих');
		} 
		catch (e) 
		{
			_error = 'Ошибка загрузки заказов: ${e.toString()}';
			print('❌ Ошибка при загрузке заказов: $e');
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
		_currentOrders = await DataService.getOrdersForWorkplace(_currentWorkplace!.id, true);

		// Если есть предыдущее рабочее место, загружаем и его заказы
		if (_currentWorkplace!.previousWorkplace != null) {
		_pendingOrders = await DataService.getOrdersForWorkplace(_currentWorkplace!.id, false);
		} 
		else 
		{
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
	Future<void> refreshOrders() async 
	{
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

		// Метод обновления с индикацией
	Future<void> refreshOrdersWithFeedback() async 
	{
		if (_isRefreshing) return;  // защита от двойного нажатия
		
		_isRefreshing = true;
		notifyListeners();
		
		try 
		{
			await refreshOrders();  // твой существующий метод
		} 
		finally 
		{
			_isRefreshing = false;
			notifyListeners();
		}
	}

	// Периодическое автообновление
	void _startAutoRefresh() 
	{
		_refreshTimer?.cancel();
		_refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) async
		{
			try
			{
				await _loadOrdersParallel();
				notifyListeners();
			}
			catch (e)
			{
				print('⚠️ Ошибка автообновления: $e');
			}
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

	@override
	void dispose() {
		stopAutoRefresh();
		super.dispose();
	}
	}