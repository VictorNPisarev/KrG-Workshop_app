import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/orderInProduct.dart';
import '../models/workplace.dart';

class DataService
{
    static const String _baseUrl = 'https://script.google.com/macros/s/AKfycbzoDyvGU4ZHKg4oy1rGmxvxLTfnMATV21eYUzTFsj4pTxz3ii3sqw-i6fk5vElvrqBR-w/exec';
    static final http.Client _client = http.Client();
    
    // Кэшированные данные на случай падения API
    static List<Workplace>? _cachedWorkplaces;
    static DateTime? _lastCacheUpdate;
    



    // Получение рабочих мест
    static Future<List<Workplace>> getWorkplaces() async
    {
        print('🚀 GAS запрос: getWorkplaces');
        
        try
        {
            final response = await http.get(
                Uri.parse('$_baseUrl?action=getWorkplaces'),
            );
            
            print('✅ Ответ получен, статус: ${response.statusCode}');
            print('📦 Длина ответа: ${response.body.length} символов');
            
            if (response.statusCode == 200)
            {
                return _parseWorkplacesResponse(response.body);
            }
            else
            {
                throw Exception('HTTP ${response.statusCode}');
            }
        }
        catch (e)
        {
            print('❌ Ошибка в getWorkplaces: $e');
            rethrow;
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
        try
        {
            final response = await http.get(
                Uri.parse('$_baseUrl?action=getOrdersByWorkplace&workplaceId=$workplaceId'),
                headers: {'Content-Type': 'application/json'},
            );

            print('✅ORders Ответ получен, статус: ${response.statusCode}');
            print('📦 Длина ответа: ${response.body.length} символов');

            if (response.statusCode == 200)
            {
                return _parseOrdersResponse(response.body);
            }
            else
            {
                throw Exception('HTTP ${response.statusCode}');
            }
        }
        catch (e)
        {
            print('❌ Ошибка в getOrdersByWorkplace: $e');
            rethrow;
        }
    }

    static List<OrderInProduct> _parseOrdersResponse(String responseBody)
    {
        try
        {
            print('🔧 Парсинг JSON ответа...');
            
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

    
    // Обновление статуса заказа
    static Future<bool> updateOrderStatus({
        required String orderId,
        required String workplaceId,
        required OrderStatus status,
        String comment = '',
    }) async
    {
        try
        {
            final response = await _client.post(
                Uri.parse(_baseUrl),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                    'action': 'update_order',
                    'order_id': orderId,
                    'workplace_id': workplaceId,
                    'status': status.name,
                    'comment': comment,
                    'timestamp': DateTime.now().toIso8601String(),
                }),
            );
            
            return response.statusCode == 200;
        }
        catch (e)
        {
            // При ошибке сети возвращаем false
            print('Ошибка обновления: $e');
            return false;
        }
    }
    
    // Mock-данные на случай падения API
    static List<Workplace> _getMockWorkplaces()
    {
        return [
            Workplace(
                id: '1', 
                name: 'Торцовка', 
                previousWorkPlace: null, 
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