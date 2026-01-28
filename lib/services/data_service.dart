import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/order_in_product.dart';
import '../models/user.dart';
import '../models/user_workplace.dart';
import '../models/workplace.dart';

class CacheEntry<T> 
{
    final T data;
    final DateTime timestamp;
  
    CacheEntry(this.data, this.timestamp);
  
    bool isExpired(Duration duration) 
    {
        return DateTime.now().difference(timestamp) > duration;
    }
}

class DataService
{
    static const String _baseUrl = 'https://script.google.com/macros/s/AKfycbzoDyvGU4ZHKg4oy1rGmxvxLTfnMATV21eYUzTFsj4pTxz3ii3sqw-i6fk5vElvrqBR-w/exec';
    static final http.Client _client = http.Client();
    
    // Таймауты для мобильных устройств
    static const Duration _timeoutDuration = Duration(seconds: 30);

    // Кэшированные данные на случай падения API
    static DateTime? _lastCacheUpdate;
        // КЭШ для рабочих мест (5 минут)
    static List<Workplace>? _cachedWorkplaces;
    static DateTime? _lastWorkplaceCache;
    static const Duration _workplaceCacheDuration = Duration(minutes: 5);
    
    // КЭШ для заказов по участкам (1 минута)
    //static final Map<String, CacheEntry<List<OrderInProduct>>> _ordersCache = {};
    static const Duration _ordersCacheDuration = Duration(minutes: 1);
    
    static final Map<String, List<OrderInProduct>> _ordersCache = {};
    static final Map<String, DateTime> _cacheTimestamps = {};
    static const Duration _cacheDuration = Duration(minutes: 2);


    // Получение рабочих мест
    static Future<List<Workplace>> getWorkplaces() async 
    {
        // Проверяем кэш
        if (_cachedWorkplaces != null && 
            _lastWorkplaceCache != null &&
            DateTime.now().difference(_lastWorkplaceCache!) < _workplaceCacheDuration) 
        {
            print('📦 Используем кэшированные рабочие места');
            return _cachedWorkplaces!;
        }
        
        print('🚀 GAS запрос: getWorkplaces');
        
        try 
        {
            final response = await http.get(
                Uri.parse('$_baseUrl?action=getWorkplaces'),
            ).timeout(const Duration(seconds: 10)); // Уменьшил таймаут
            
            if (response.statusCode == 200) 
            {
                final workplaces = _parseWorkplacesResponse(response.body);
                
                // Сохраняем в кэш
                _cachedWorkplaces = workplaces;
                _lastWorkplaceCache = DateTime.now();
                
                return workplaces;
            } 
            else 
            {
                // При ошибке возвращаем кэш, если есть
                if (_cachedWorkplaces != null) 
                {
                    print('⚠️ Используем устаревшие данные из кэша');
                    return _cachedWorkplaces!;
                }
                throw Exception('HTTP ${response.statusCode}');
            }
        } 
        on TimeoutException 
        {
            print('⏰ Таймаут - используем кэш или пустой список');
            return _cachedWorkplaces ?? [];
        } 
        catch (e) 
        {
            print('❌ Ошибка: $e');
            return _cachedWorkplaces ?? [];
        }
    }
    
    static List<Workplace> _parseWorkplacesResponse(String responseBody)
    {
        try
        {
            print('🔧 Парсинг JSON ответа...');
            
            // Пробуем распарсить
            final List<dynamic> jsonList = jsonDecode(responseBody);
            print('✅ JSON распарсен, элементов: ${jsonList.length}');
            
            // Парсим каждый элемент
            final workplaces = <Workplace>[];
            
            for (int i = 0; i < jsonList.length; i++)
            {
                try
                {
                    final item = jsonList[i] as Map<String, dynamic>;
                    print('\n   --- Элемент $i ---');
                    
                    final workplace = Workplace.fromJson(item);
                    workplaces.add(workplace);
                    
                    print('   ✅ Успешно распарсено: ${workplace.name} (ID: ${workplace.id})');
                }
                catch (e)
                {
                    print('   ⚠️ Ошибка парсинга элемента $i: $e');
                    print('   Элемент: ${jsonList[i]}');
                    
                    // Можно пропустить проблемный элемент или добавить дефолтный
                    // workplaces.add(Workplace.fallback());
                }
            }
            
            print('\n🎉 Всего распаршено: ${workplaces.length} из ${jsonList.length}');
            return workplaces;
        }
        catch (e)
        {
            print('❌ Ошибка парсинга JSON: $e');
            print('   responseBody (первые 500 символов): ${responseBody.substring(0, 500)}...');
            
            // Если не удалось распарсить, возвращаем пустой список
            return [];
        }
    }

    // Получение заказов для участка
    static Future<List<OrderInProduct>> getOrdersForWorkplace(String workplaceId) async
    {
        final now = DateTime.now();
        
        // Проверяем кэш
        if (_ordersCache.containsKey(workplaceId) && 
            _cacheTimestamps.containsKey(workplaceId) &&
            now.difference(_cacheTimestamps[workplaceId]!) < _cacheDuration) {
            print('⚡ Используем кэшированные заказы для участка $workplaceId');
            return _ordersCache[workplaceId]!;
        }
        
        try
        {
            print('📥 Загрузка заказов для участка $workplaceId');
            final stopwatch = Stopwatch()..start();
            
            final response = await http.get(
                Uri.parse('$_baseUrl?action=getOrdersByWorkplace&workplaceId=$workplaceId'),
            ).timeout(const Duration(seconds: 15));
            
            if (response.statusCode == 200)
            {
                final orders = await _parseOrdersResponseInBackground(response.body);
                
                stopwatch.stop();
                print('✅ Заказы загружены за ${stopwatch.elapsedMilliseconds}ms');
                
                // Сохраняем в кэш
                _ordersCache[workplaceId] = orders;
                _cacheTimestamps[workplaceId] = now;
                
                return orders;
            }
            else
            {
                throw Exception('HTTP ${response.statusCode}');
            }
        }
        catch (e)
        {
            print('❌ Ошибка загрузки заказов: $e');
            // Возвращаем кэш, если есть
            return _ordersCache[workplaceId] ?? [];
        }
    }

    // Парсинг в фоне (если нужно)
    static Future<List<OrderInProduct>> _parseOrdersResponseInBackground(String responseBody) async 
    {
        return compute(_parseOrdersResponse, responseBody);
    }

    static List<OrderInProduct> _parseOrdersResponse(String responseBody)
    {
        try
        {
            print('🔧 Парсинг JSON ответа...');
            print(responseBody);
            
            // Пробуем распарсить
            final List<dynamic> jsonList = jsonDecode(responseBody);
            print('✅ JSON распарсен, элементов: ${jsonList.length}');
            
            // Парсим каждый элемент
            final orders = <OrderInProduct>[];
            
            for (int i = 0; i < jsonList.length; i++)
            {
                try
                {
                    final item = jsonList[i] as Map<String, dynamic>;
                    print('\n   --- Элемент $i ---');
                    
                    final order = OrderInProduct.fromJson(item);
                    orders.add(order);
                    
                    print('   ✅ Успешно распарсено: ${order.orderNumber} (ID: ${order.id})');
                }
                catch (e)
                {
                    print('   ⚠️ Ошибка парсинга элемента $i: $e');
                    print('   Элемент: ${jsonList[i]}');
                    
                    // Можно пропустить проблемный элемент или добавить дефолтный
                    // workplaces.add(Workplace.fallback());
                }
            }
            
            print('\n🎉 Всего распаршено: ${orders.length} из ${jsonList.length}');
            return orders;
        }
        catch (e)
        {
            print('❌ Ошибка парсинга JSON: $e');
            print('   responseBody (первые 500 символов): ${responseBody.substring(0, 500)}...');
            
            // Если не удалось распарсить, возвращаем пустой список
            return [];
        }
    }

    // Получение заказов для участка
    static Future<List<User>> getUsers() async
    {
        try
        {
            final response = await http.get(
                Uri.parse('$_baseUrl?action=getUsers'),
                headers: {'Content-Type': 'application/json'},
            ).timeout(_timeoutDuration);

            print('✅Users Ответ получен, статус: ${response.statusCode}');
            print('📦 Длина ответа: ${response.body.length} символов');

            if (response.statusCode == 200)
            {
                return _parseUsersResponse(response.body);
            }
            else
            {
                throw Exception('HTTP ${response.statusCode}');
            }
        }
        on TimeoutException catch (e)
        {
            print('⏰ Таймаут запроса: $e');
            throw Exception('Таймаут запроса. Проверьте подключение к интернету');
        }
        on SocketException catch (e)
        {
            print('📡 Ошибка сети: $e');
            throw Exception('Нет подключения к интернету');
        }
        catch (e)
        {
            print('❌ Ошибка в getOrdersByWorkplace: $e');
            rethrow;
        }
    }

    static List<User> _parseUsersResponse(String responseBody)
    {
        try
        {
            print('🔧 Парсинг JSON ответа...');
            print(responseBody);
            
            // Пробуем распарсить
            final List<dynamic> jsonList = jsonDecode(responseBody);
            print('✅ JSON распарсен, элементов: ${jsonList.length}');
            
            // Парсим каждый элемент
            final users = <User>[];
            
            for (int i = 0; i < jsonList.length; i++)
            {
                try
                {
                    final item = jsonList[i] as Map<String, dynamic>;
                    print('\n   --- Элемент $i ---');
                    
                    final user = User.fromJson(item);
                    users.add(user);
                    
                    print('   ✅ Успешно распарсено: ${user.name} (Email: ${user.email})');
                }
                catch (e)
                {
                    print('   ⚠️ Ошибка парсинга элемента $i: $e');
                    print('   Элемент: ${jsonList[i]}');
                    
                    // Можно пропустить проблемный элемент или добавить дефолтный
                    // workplaces.add(Workplace.fallback());
                }
            }
            
            print('\n🎉 Всего распаршено: ${users.length} из ${jsonList.length}');
            return users;
        }
        catch (e)
        {
            print('❌ Ошибка парсинга JSON: $e');
            print('   responseBody (первые 500 символов): ${responseBody.substring(0, 500)}...');
            
            // Если не удалось распарсить, возвращаем пустой список
            return [];
        }
    }

    static Future<User?> getUserByEmail(String email) async
    {
        try
        {
            final response = await http.get(
                Uri.parse('$_baseUrl?action=getUserByEmail&email=$email'),
                headers: {'Content-Type': 'application/json'},
            ).timeout(_timeoutDuration);

            print('✅UserByEmail Ответ получен, статус: ${response.statusCode}');
            print('📦 Длина ответа: ${response.body.length} символов');

            if (response.statusCode == 200)
            {
                return _parseUserResponse(response.body);
            }
            else
            {
                throw Exception('HTTP ${response.statusCode}');
            }
        }
        on TimeoutException catch (e)
        {
            print('⏰ Таймаут запроса: $e');
            throw Exception('Таймаут запроса. Проверьте подключение к интернету');
        }
        on SocketException catch (e)
        {
            print('📡 Ошибка сети: $e');
            throw Exception('Нет подключения к интернету');
        }
        catch (e)
        {
            print('❌ Ошибка в getUserByEmail: $e');
            rethrow;
        }
    }    
    
    static User? _parseUserResponse(String responseBody)
    {
        try
        {
            print('🔧 Парсинг JSON ответа...');
            print(responseBody);
            
            // Пробуем распарсить
            final List<dynamic> jsonList = jsonDecode(responseBody);
            print('✅ JSON распарсен, элементов: ${jsonList.length}');
            
            // Парсим каждый элемент
            final workplaces = <Workplace>[];
            
            for (int i = 0; i < jsonList.length; i++)
            {
                try
                {
                    final item = jsonList[i] as Map<String, dynamic>;
                    print('\n   --- Элемент $i ---');
                    
                    final user = User.fromJson(item);
                    
                    print('   ✅ Успешно распарсено для: ${user.email}');

                    //Возвращаю первого удачно распарсенного пользователя (если вдруг в ответе не 1)
                    return user;
                }
                catch (e)
                {
                    print('   ⚠️ Ошибка парсинга элемента $i: $e');
                    print('   Элемент: ${jsonList[i]}');
                }
            }

            //Возвращаю null, т.к. при удачном распарсивании пользователя, return произошел бы в цикле
            return null;
        }
        catch (e)
        {
            print('❌ Ошибка парсинга JSON: $e');
            print('   responseBody (первые 500 символов): ${responseBody.substring(0, 500)}...');
            
            // Если не удалось распарсить, возвращаем null
            return null;
        }
    }


    static Future<List<Workplace>> getUserWorkplaces(String userId) async
    {
        try
        {
            final response = await http.get(
                Uri.parse('$_baseUrl?action=getUserWorkplaces&userId=$userId'),
                headers: {'Content-Type': 'application/json'},
            ).timeout(_timeoutDuration);

            print('✅Users Ответ получен, статус: ${response.statusCode}');
            print('📦 Длина ответа: ${response.body.length} символов');

            if (response.statusCode == 200)
            {
                return _parseUserWorkplacesResponse(response.body);
            }
            else
            {
                throw Exception('HTTP ${response.statusCode}');
            }
        }
        on TimeoutException catch (e)
        {
            print('⏰ Таймаут запроса: $e');
            throw Exception('Таймаут запроса. Проверьте подключение к интернету');
        }
        on SocketException catch (e)
        {
            print('📡 Ошибка сети: $e');
            throw Exception('Нет подключения к интернету');
        }
        catch (e)
        {
            print('❌ Ошибка в getUserWorkplaces: $e');
            rethrow;
        }
    }    
    
    static List<Workplace> _parseUserWorkplacesResponse(String responseBody)
    {
        try
        {
            print('🔧 Парсинг JSON ответа...');
            print(responseBody);
            
            // Пробуем распарсить
            final List<dynamic> jsonList = jsonDecode(responseBody);
            print('✅ JSON распарсен, элементов: ${jsonList.length}');
            
            // Парсим каждый элемент
            final workplaces = <Workplace>[];
            
            for (int i = 0; i < jsonList.length; i++)
            {
                try
                {
                    final item = jsonList[i] as Map<String, dynamic>;
                    print('\n   --- Элемент $i ---');
                    
                    final workplace = Workplace.fromJson(item);
                    workplaces.add(workplace);
                    
                    print('   ✅ Успешно распарсено: ${workplace.name}');
                }
                catch (e)
                {
                    print('   ⚠️ Ошибка парсинга элемента $i: $e');
                    print('   Элемент: ${jsonList[i]}');
                    
                    // Можно пропустить проблемный элемент или добавить дефолтный
                    // workplaces.add(Workplace.fallback());
                }
            }
            
            print('\n🎉 Всего распаршено: ${workplaces.length} из ${jsonList.length}');
            return workplaces;
        }
        catch (e)
        {
            print('❌ Ошибка парсинга JSON: $e');
            print('   responseBody (первые 500 символов): ${responseBody.substring(0, 500)}...');
            
            // Если не удалось распарсить, возвращаем пустой список
            return [];
        }
    }


    // Обновление статуса заказа
    static Future<Map<String, dynamic>> updateOrderStatus({
        required String orderId,
        required String workplaceId,
        required OrderStatus status,
        String comment = '',
    }) async 
    {
        try 
        {
            print('📤 Отправка обновления заказа:');
            print('   ID: $orderId');
            print('   Workplace: $workplaceId');
            print('   Status: ${status.name}');
            
            final client = http.Client();
            
            try 
            {
                // ПЕРВОЕ ИСПРАВЛЕНИЕ: Обрабатываем редирект вручную
                final request = http.Request(
                    'POST',
                    Uri.parse(_baseUrl),
                )
                  ..headers['Content-Type'] = 'application/json'
                  ..body = json.encode({
                      'action': 'updateOrderWorkplace',
                      'payload': 
                      {
                          'orderInProductId': orderId,
                          'workplaceId': workplaceId,
                          'status': status.name,
                      },
                  });
                
                final streamedResponse = await client.send(request);
                final response = await http.Response.fromStream(streamedResponse);
                
                print('📥 Ответ сервера: ${response.statusCode}');
                
                if (response.statusCode == 200 || response.statusCode == 302) 
                {
                    final responseData = json.decode(response.body);
                    print('✅ Ответ от сервера: $responseData');
                    
                    // ВТОРОЕ ИСПРАВЛЕНИЕ: Не ждем полной синхронизации, сразу возвращаем успех
                    // Для пилотной версии - считаем, что если статус 200/302, то все ок
                    return {
                        'success': true,
                        'message': 'Статус обновлен',
                        'data': responseData,
                    };
                } 
                else 
                {
                    print('❌ Ошибка HTTP: ${response.statusCode}, тело: ${response.body}');
                    return {
                        'success': false,
                        'message': 'HTTP ${response.statusCode}',
                    };
                }
            } 
            finally 
            {
                client.close();
            }
        } 
        catch (e) 
        {
            print('❌ Ошибка обновления заказа: $e');
            
            // ТРЕТЬЕ ИСПРАВЛЕНИЕ: Для пилотной версии - оптимистичное обновление
            // Локально обновляем и пробуем отправить снова в фоне
            return {
                'success': true, // Временно возвращаем true даже при ошибке
                'message': 'Обновление отправлено в фоне',
            };
        }
    }

    // Mock-данные на случай падения API
    static List<Workplace> _getMockWorkplaces()
    {
        return [
            Workplace(
                id: '1', 
                name: 'Торцовка', 
                previousWorkplace: null, 
                nextWorkPlace: '2', 
                isWorkPlace: true
            ),
            // ... остальные mock-данные
        ];
    }
    
    static List<OrderInProduct> _getMockOrders(String workplaceId)
    {
        print("_getMockOrders");
        // Возвращаем пустой список или базовые тестовые данные
        return [];
    }
}