import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/order_in_product.dart';
import '../models/order_trace.dart';
import '../models/user.dart';
import '../models/workplace.dart';
import '../models/workplace_status.dart';
import '../utils/platform_utils.dart';

class DataService 
{
	static const String _baseUrl =
		'https://script.google.com/macros/s/AKfycbzoDyvGU4ZHKg4oy1rGmxvxLTfnMATV21eYUzTFsj4pTxz3ii3sqw-i6fk5vElvrqBR-w/exec';
	static final http.Client _client = http.Client();

	// Таймауты для мобильных устройств
	static const Duration _timeoutDuration = Duration(seconds: 120);

	// Кэшированные данные
	static List<Workplace>? _cachedWorkplaces;
	static DateTime? _lastWorkplaceCache;
	static final Map<String, List<OrderInProduct>> _ordersCache = {};
	static final Map<String, DateTime> _cacheTimestamps = {};
	static const Duration _cacheDuration = Duration(minutes: 5);

	// Очистка кэша
	static void clearCache() {
		_cachedWorkplaces = null;
		_lastWorkplaceCache = null;
		_ordersCache.clear();
		_cacheTimestamps.clear();
		print('🧹 Кэш DataService очищен');
	}

	// Получение рабочих мест
	static Future<List<Workplace>> getWorkplaces() async 
	{
		final now = DateTime.now();

		// Проверяем кэш (5 минут)
		if (_cachedWorkplaces != null &&
			_lastWorkplaceCache != null &&
			now.difference(_lastWorkplaceCache!) < _cacheDuration) {
		print('📦 Используем кэшированные рабочие места (${_cachedWorkplaces!.length})');
		return _cachedWorkplaces!;
		}

		print('🚀 GAS запрос: getWorkplaces');

		try 
		{
		final response = await _callGAS('getWorkplaces');
		/*final response = await http
			.get(
				Uri.parse('$_baseUrl?action=getWorkplaces'),
			)
			.timeout(_timeoutDuration);*/

		print('✅ Ответ получен, статус: ${response.statusCode}');

		//if (response.statusCode == 200) 
		//{
			final workplaces = await compute(_parseWorkplacesResponse, response.body);

			// Сохраняем в кэш
			_cachedWorkplaces = workplaces;
			_lastWorkplaceCache = now;

			print('✅ Загружено рабочих мест: ${workplaces.length}');
			return workplaces;
		/*} 
		else 
		{
			// При ошибке возвращаем кэш, если есть
			if (_cachedWorkplaces != null) {
			print('⚠️ Используем устаревшие данные из кэша');
			return _cachedWorkplaces!;
			}
			throw Exception('HTTP ${response.statusCode}');
		}*/
		} 
		on TimeoutException catch (e) 
		{
		print('⏰ Таймаут запроса: $e');
		return _cachedWorkplaces ?? [];
		} 
		on SocketException catch (e) 
		{
		print('📡 Ошибка сети: $e');
		return _cachedWorkplaces ?? [];
		} 
		catch (e) 
		{
		print('❌ Ошибка в getWorkplaces: $e');
		return _cachedWorkplaces ?? [];
		}

	}

	static List<Workplace> _parseWorkplacesResponse(String responseBody) {
		try {
		final List<dynamic> jsonList = jsonDecode(responseBody);
		final workplaces = <Workplace>[];

		for (int i = 0; i < jsonList.length; i++) {
			try {
			final item = jsonList[i] as Map<String, dynamic>;
			final workplace = Workplace.fromJson(item);
			workplaces.add(workplace);
			} catch (e) {
			print('   ⚠️ Ошибка парсинга элемента $i: $e');
			}
		}

		return workplaces;
		} catch (e) {
		print('❌ Ошибка парсинга JSON: $e');
		return [];
		}
	}

	// Получение заказов для участка
	static Future<List<OrderInProduct>> getOrdersForWorkplace(String workplaceId, [active = false]) async 
	{
		final now = DateTime.now();

		// Проверяем кэш
		/*if (_ordersCache.containsKey(workplaceId) &&
			_cacheTimestamps.containsKey(workplaceId) &&
			now.difference(_cacheTimestamps[workplaceId]!) < _cacheDuration) {
		print('📦 Используем кэшированные заказы для участка $workplaceId');
		return _ordersCache[workplaceId]!;
		}*/

		try 
		{
		print('📥 Загрузка заказов для участка $workplaceId');

		final action = active ? 'getActiveOrdersByWorkplace' : 'getPendingOrdersByWorkplace';

		final response = await _callGAS(action, params: {'workplaceId': workplaceId});
			// Используем compute для парсинга в фоне
			final orders = await compute(_parseOrdersResponse, response.body);

			// Сохраняем в кэш
			_ordersCache[workplaceId] = orders;
			_cacheTimestamps[workplaceId] = now;

			print('✅ Заказов загружено: ${orders.length}');
			return orders;
		/*} else {
			throw Exception('HTTP ${response.statusCode}');
		}*/
		} 
		on TimeoutException catch (e) 
		{
		print('⏰ Таймаут запроса: $e');
		return [];//_ordersCache[workplaceId] ?? [];
		} 
		on SocketException catch (e) 
		{
		print('📡 Ошибка сети: $e');
		return [];//_ordersCache[workplaceId] ?? [];
		} 
		catch (e) 
		{
		print('❌ Ошибка в getOrdersByWorkplace: $e');
		return [];//_ordersCache[workplaceId] ?? [];
		}


	}

	// Получение всех заказов для участка
	static Future<List<OrderInProduct>> getAllOrdersForWorkplace(String workplaceId) async 
	{
		final now = DateTime.now();

		// Проверяем кэш
		/*if (_ordersCache.containsKey(workplaceId) &&
			_cacheTimestamps.containsKey(workplaceId) &&
			now.difference(_cacheTimestamps[workplaceId]!) < _cacheDuration) {
		print('📦 Используем кэшированные заказы для участка $workplaceId');
		return _ordersCache[workplaceId]!;
		}*/

		try 
		{
		print('📥 Загрузка заказов для участка $workplaceId');

		final action = 'getActiveAndPendingOrdersByWorkplace';

		final response = await _callGAS(action, params: {'workplaceId': workplaceId});
			// Используем compute для парсинга в фоне
			final orders = await compute(_parseOrdersResponse, response.body);

			// Сохраняем в кэш
			_ordersCache[workplaceId] = orders;
			_cacheTimestamps[workplaceId] = now;

			print('✅ Заказов загружено: ${orders.length}');
			return orders;
		} 
		on TimeoutException catch (e) 
		{
		print('⏰ Таймаут запроса: $e');
		return [];//_ordersCache[workplaceId] ?? [];
		} 
		on SocketException catch (e) 
		{
		print('📡 Ошибка сети: $e');
		return [];//_ordersCache[workplaceId] ?? [];
		} 
		catch (e) 
		{
		print('❌ Ошибка в getOrdersByWorkplace: $e');
		return [];//_ordersCache[workplaceId] ?? [];
		}


	}

	// Парсинг заказов в фоне
	static List<OrderInProduct> _parseOrdersResponse(String responseBody) {
		try {
		final List<dynamic> jsonList = jsonDecode(responseBody);
		final orders = <OrderInProduct>[];

		for (int i = 0; i < jsonList.length; i++) {
			try {
			final item = jsonList[i] as Map<String, dynamic>;
			final order = OrderInProduct.fromJson(item);
			orders.add(order);
			} catch (e) {
			print('   ⚠️ Ошибка парсинга элемента $i: $e');
			}
		}

		return orders;
		} catch (e) {
		print('❌ Ошибка парсинга JSON: $e');
		return [];
		}
	}

	// Параллельная загрузка заказов для нескольких участков
	static Future<Map<String, List<OrderInProduct>>> getOrdersForMultipleWorkplaces(List<String> workplaceIds) async 
	{
		try 
		{
		print('🚀 Параллельная загрузка заказов для ${workplaceIds.length} участков');

		final stopwatch = Stopwatch()..start();

		// Создаем список Future для каждого участка
		final List<Future<List<OrderInProduct>>> futures = [];
		for (final workplaceId in workplaceIds) 
		{
			futures.add(getOrdersForWorkplace(workplaceId));
		}

		// Загружаем параллельно
		final List<List<OrderInProduct>> results = await Future.wait(futures);

		// Собираем результат в Map
		final Map<String, List<OrderInProduct>> resultMap = {};
		for (int i = 0; i < workplaceIds.length; i++) {
			resultMap[workplaceIds[i]] = results[i];
		}

		print('✅ Всего заказов загружено ${resultMap.length}');

		stopwatch.stop();
		print('✅ Параллельная загрузка завершена за ${stopwatch.elapsedMilliseconds}ms');

		return resultMap;
		} catch (e) {
		print('❌ Ошибка параллельной загрузки: $e');
		rethrow;
		}
	}

	static Future<User?> getUserByEmail(String email) async 
	{
		try 
		{
		final response = await _callGAS('getUserByEmail', params: {'email': email});

		return _parseUserResponse(response.body);
		/*final response = await http.get(
			Uri.parse('$_baseUrl?action=getUserByEmail&email=$email'),
		).timeout(_timeoutDuration);

		if (response.statusCode == 200) 
		{
			return _parseUserResponse(response.body);
		} 
		else 
		{
			throw Exception('HTTP ${response.statusCode}');
		}*/
		} catch (e) {
		print('❌ Ошибка в getUserByEmail: $e');
		rethrow;
		}
	}

	static User? _parseUserResponse(String responseBody) {
		try {
		final List<dynamic> jsonList = jsonDecode(responseBody);

		for (int i = 0; i < jsonList.length; i++) {
			try {
			final item = jsonList[i] as Map<String, dynamic>;
			return User.fromJson(item);
			} catch (e) {
			print('   ⚠️ Ошибка парсинга элемента $i: $e');
			}
		}

		return null;
		} catch (e) {
		print('❌ Ошибка парсинга JSON: $e');
		return null;
		}
	}

	static Future<List<Workplace>> getUserWorkplaces(String userId) async 
	{
		try 
		{
		final response = await _callGAS('getUserWorkplaces', params: {'userId': userId});

		return _parseUserWorkplacesResponse(response.body);
		/*final response = await http.get(
			Uri.parse('$_baseUrl?action=getUserWorkplaces&userId=$userId'),
		).timeout(_timeoutDuration);

		if (response.statusCode == 200) {
			return _parseUserWorkplacesResponse(response.body);
		} else {
			throw Exception('HTTP ${response.statusCode}');
		}*/
		} 
		catch (e) 
		{
		print('❌ Ошибка в getUserWorkplaces: $e');
		rethrow;
		}
	}

	static List<Workplace> _parseUserWorkplacesResponse(String responseBody) {
		try {
		final List<dynamic> jsonList = jsonDecode(responseBody);
		final workplaces = <Workplace>[];

		for (int i = 0; i < jsonList.length; i++) {
			try {
			final item = jsonList[i] as Map<String, dynamic>;
			final workplace = Workplace.fromJson(item);
			workplaces.add(workplace);
			} catch (e) {
			print('   ⚠️ Ошибка парсинга элемента $i: $e');
			}
		}

		return workplaces;
		} catch (e) {
		print('❌ Ошибка парсинга JSON: $e');
		return [];
		}
	}

	// Обновление статуса заказа (оптимизированное)
	static Future<Map<String, dynamic>> updateOrderStatus({
		required String orderId,
		required String workplaceId,
		required String? userId,
		required OrderStatus status,
		String comment = '',
	}) async {
		try {
		print('📤 Отправка обновления заказа:');
		print('   ID: $orderId');
		print('   Workplace: $workplaceId');
		print('   Status: ${status.name}');

		final client = http.Client();
		//client.maxRedirects = 5; // Разрешаем редиректы

		final action = status == OrderStatus.completed ? 'completeOrderWorkplace' : 'updateOrderWorkplace';

		try 
		{
			final response = await client
				.post(
				Uri.parse(_baseUrl),
				headers: {'Content-Type': 'text/plain;charset=utf-8'},
				body: json.encode({
					'action': action,
					'payload': {
					'orderInProductId': orderId,
					'workplaceId': workplaceId,
					'userId': userId,
					'status': status.name,
					'source': '${PlatformUtils.platform} API',  // источник
					},
				}),
				)
				.timeout(const Duration(seconds: 20));

			print('📥 Ответ сервера: ${response.statusCode}');

			// Если 302 или 200 - считаем успехом
			if (response.statusCode == 200 || response.statusCode == 302) {
			print('✅ Заказ обновлен на сервере');
			return {'success': true, 'message': 'OK'};
			}

			return {'success': false, 'message': 'HTTP ${response.statusCode}'};
		} finally {
			client.close();
		}
		} catch (e) {
		print('⚠️ Ошибка сети, но продолжаем работу: $e');
		// Для пилота - возвращаем успех даже при ошибке
		return {'success': true, 'message': 'Обновлено локально'};
		}
	}

	// Универсальный метод для всех запросов
	static Future<http.Response> _callGAS(String action, {Map<String, dynamic>? params}) async 
	{
		if(PlatformUtils.isWeb)
		{
			return _postGAS(action, params: params);
		}
		else
		{
			return _getGAS(action, params: params);
		}
	}
	
	static Future<http.Response> _postGAS(String action, {Map<String, dynamic>? params}) async 
	{
		final client = http.Client();

		try
		{
			/*final response = await client
				.post(
				Uri.parse(_baseUrl),
				headers: {'Content-Type': 'text/plain;charset=utf-8'},
				body: json.encode({
						'action': action,
						'params': params ?? {},
					}),
				).timeout(_timeoutDuration);*/

			final response = await http
				.post(
				Uri.parse(_baseUrl),
				headers: {'Content-Type': 'text/plain;charset=utf-8'},
				body: json.encode({
						'action': action,
						'params': params ?? {},
					}),
				).timeout(_timeoutDuration);

			print('📥 Ответ сервера: ${response.statusCode}');

			if (response.statusCode == 200) 
			{
			return response;
			} 
			else 
			{
			throw Exception('HTTP ${response.statusCode}');
			}
		}
		finally
		{
			client.close();
		}
	}

	static Future<http.Response> _getGAS(String action, {Map<String, dynamic>? params}) async 
	{
		try
		{
			// Начинаем с action
			String queryString = 'action=$action';
			
			// Добавляем все параметры
			if (params != null) {
			params.forEach((key, value) {
				// URL-кодируем ключи и значения
				final encodedKey = Uri.encodeQueryComponent(key);
				final encodedValue = Uri.encodeQueryComponent(value.toString());
				queryString += '&$encodedKey=$encodedValue';
			});
			}
			
			// Формируем полный URL
			final Uri uri = Uri.parse('$_baseUrl?$queryString');
			
			print('📤 GET запрос: $uri');
			
			final response = await http
				.get(uri)
				.timeout(_timeoutDuration);
			
			print('📥 Ответ сервера: ${response.statusCode}');
			
			if (response.statusCode == 200) 
			{
			return response;
			} 
			else 
			{
			throw Exception('HTTP ${response.statusCode}');
			}
		}
		catch (e)
		{
			print('❌ Ошибка в _getGAS: $e');
			rethrow;
		}
	}

	static Future<List<OrderTrace>> getOrderTrace(String orderNumber) async 
	{
		try 
		{
			print('🔍 Поиск заказа: $orderNumber');
			
			final response = await _callGAS('getOrderTrace', params: {'orderNumber': orderNumber});
			
			if (response.statusCode == 200) 
			{
				final data = jsonDecode(response.body);
				final orders = data['orders'] as List;
				
				return orders.map((o) => OrderTrace.fromJson(o)).toList();
			} 
			else 
			{
				throw Exception('HTTP ${response.statusCode}');
			}
		} 
		catch (e) 
		{
			print('❌ Ошибка поиска заказа: $e');
			return [];
		}
	}

	static Future<Map<String, dynamic>> blockOrder({required String orderId, required String workplaceId, required String userId, required String reason,}) async
	{
		try
		{
			print('🚫 Блокировка заказа: $orderId на участке $workplaceId');
			print('	 Причина: $reason');

			final action = 'blockOrderWorkplace';
			//final isGAS = _currentBaseUrl.contains('script.google.com');

			final Map<String, dynamic> body;
			String url;

//			if (isGAS)
			{
				url = _baseUrl;
				body =
				{
					'action': action,
					'payload':
					{
						'orderInProductId': orderId,
						'workplaceId': workplaceId,
						'userId': userId,
						'reason': reason,
						'source': '${PlatformUtils.platform} API',  // источник
					},
				};
			}
//			else
//			{
//				url = '$_baseUrl/$action';
//				body = {
//					'orderId': orderId,
//					'workplaceId': workplaceId,
//					'userId': userId,
//					'reason': reason,
//				};
//			}

			final response = await http.post(
				Uri.parse(url),
				headers: {'Content-Type': 'application/json'},
				body: json.encode(body),
			).timeout(const Duration(seconds: 10));

			if (response.statusCode == 200)
			{
				return {'success': true, 'message': 'OK'};
			}
			else
			{
				return {'success': false, 'message': 'HTTP ${response.statusCode}'};
			}
		}
		catch (e)
		{
			print('⚠️ Ошибка блокировки: $e');
			return {'success': false, 'message': e.toString()};
		}
	}
}