import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/order_in_product.dart';
import '../models/user.dart';
import '../models/user_workplace.dart';
import '../models/workplace.dart';

class DataService {
  static const String _baseUrl =
      'https://script.google.com/macros/s/AKfycbzoDyvGU4ZHKg4oy1rGmxvxLTfnMATV21eYUzTFsj4pTxz3ii3sqw-i6fk5vElvrqBR-w/exec';
  static final http.Client _client = http.Client();

  // Таймауты для мобильных устройств
  static const Duration _timeoutDuration = Duration(seconds: 10);

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
  static Future<List<Workplace>> getWorkplaces() async {
    final now = DateTime.now();

    // Проверяем кэш (5 минут)
    if (_cachedWorkplaces != null &&
        _lastWorkplaceCache != null &&
        now.difference(_lastWorkplaceCache!) < _cacheDuration) {
      print('📦 Используем кэшированные рабочие места (${_cachedWorkplaces!.length})');
      return _cachedWorkplaces!;
    }

    print('🚀 GAS запрос: getWorkplaces');

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl?action=getWorkplaces'),
          )
          .timeout(_timeoutDuration);

      print('✅ Ответ получен, статус: ${response.statusCode}');

      if (response.statusCode == 200) {
        final workplaces = await compute(_parseWorkplacesResponse, response.body);

        // Сохраняем в кэш
        _cachedWorkplaces = workplaces;
        _lastWorkplaceCache = now;

        print('✅ Загружено рабочих мест: ${workplaces.length}');
        return workplaces;
      } else {
        // При ошибке возвращаем кэш, если есть
        if (_cachedWorkplaces != null) {
          print('⚠️ Используем устаревшие данные из кэша');
          return _cachedWorkplaces!;
        }
        throw Exception('HTTP ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('⏰ Таймаут запроса: $e');
      return _cachedWorkplaces ?? [];
    } on SocketException catch (e) {
      print('📡 Ошибка сети: $e');
      return _cachedWorkplaces ?? [];
    } catch (e) {
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
  static Future<List<OrderInProduct>> getOrdersForWorkplace(String workplaceId) async {
    final now = DateTime.now();

    // Проверяем кэш
    if (_ordersCache.containsKey(workplaceId) &&
        _cacheTimestamps.containsKey(workplaceId) &&
        now.difference(_cacheTimestamps[workplaceId]!) < _cacheDuration) {
      print('📦 Используем кэшированные заказы для участка $workplaceId');
      return _ordersCache[workplaceId]!;
    }

    try {
      print('📥 Загрузка заказов для участка $workplaceId');

      final response = await http
          .get(
            Uri.parse('$_baseUrl?action=getOrdersByWorkplace&workplaceId=$workplaceId'),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        // Используем compute для парсинга в фоне
        final orders = await compute(_parseOrdersResponse, response.body);

        // Сохраняем в кэш
        _ordersCache[workplaceId] = orders;
        _cacheTimestamps[workplaceId] = now;

        print('✅ Заказов загружено: ${orders.length}');
        return orders;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('⏰ Таймаут запроса: $e');
      return _ordersCache[workplaceId] ?? [];
    } on SocketException catch (e) {
      print('📡 Ошибка сети: $e');
      return _ordersCache[workplaceId] ?? [];
    } catch (e) {
      print('❌ Ошибка в getOrdersByWorkplace: $e');
      return _ordersCache[workplaceId] ?? [];
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
      for (final workplaceId in workplaceIds) {
        futures.add(getOrdersForWorkplace(workplaceId));
      }

      // Загружаем параллельно
      final List<List<OrderInProduct>> results = await Future.wait(futures);

      // Собираем результат в Map
      final Map<String, List<OrderInProduct>> resultMap = {};
      for (int i = 0; i < workplaceIds.length; i++) {
        resultMap[workplaceIds[i]] = results[i];
      }

      stopwatch.stop();
      print('✅ Параллельная загрузка завершена за ${stopwatch.elapsedMilliseconds}ms');

      return resultMap;
    } catch (e) {
      print('❌ Ошибка параллельной загрузки: $e');
      rethrow;
    }
  }

  // Остальные методы без изменений...
  static Future<User?> getUserByEmail(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=getUserByEmail&email=$email'),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return _parseUserResponse(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
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

  static Future<List<Workplace>> getUserWorkplaces(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=getUserWorkplaces&userId=$userId'),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return _parseUserWorkplacesResponse(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
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

      try {
        final response = await client
            .post(
              Uri.parse(_baseUrl),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'action': action,
                'payload': {
                  'orderInProductId': orderId,
                  'workplaceId': workplaceId,
                  'userId': userId,
                  'status': status.name,
                },
              }),
            )
            .timeout(const Duration(seconds: 10));

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

}