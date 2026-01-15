import 'dart:convert';
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
        // Если есть кэш младше 5 минут - используем его
        if (_cachedWorkplaces != null && 
            _lastCacheUpdate != null && 
            DateTime.now().difference(_lastCacheUpdate!) < const Duration(minutes: 5))
        {
            return _cachedWorkplaces!;
        }
        
        try
        {
            final response = await _client.get(
                Uri.parse('$_baseUrl?action=getWorkplaces'),
                headers: {'Content-Type': 'application/json'},
            );
            
            if (response.statusCode == 200)
            {
                final data = json.decode(response.body);
                final workplaces = (data as List)
                    .map((item) => Workplace.fromJson(item))
                    .toList();
                
                // Сохраняем в кэш
                _cachedWorkplaces = workplaces;
                _lastCacheUpdate = DateTime.now();
                
                return workplaces;
            }
            else
            {
                // Если API недоступно, используем mock-данные
                return _getMockWorkplaces();
            }
        }
        catch (e)
        {
            // При ошибке сети используем кэш или mock-данные
            return _cachedWorkplaces ?? _getMockWorkplaces();
        }
    }
    
    // Получение заказов для участка
    static Future<List<OrderInProduct>> getOrdersForWorkplace(String workplaceId) async
    {
        try
        {
            final response = await _client.get(
                Uri.parse('$_baseUrl?action=getOrdersByWorkplace&workplaceId=$workplaceId'),
                headers: {'Content-Type': 'application/json'},
            );
            
            if (response.statusCode == 200)
            {
                final data = json.decode(response.body);
                return (data as List)
                    .map((item) => OrderInProduct.fromJson(item))
                    .toList();
            }
            else
            {
                // Если API недоступно, используем mock-данные
                return _getMockOrders(workplaceId);
            }
        }
        catch (e)
        {
            // При ошибке сети используем mock-данные
            return _getMockOrders(workplaceId);
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
        // Возвращаем пустой список или базовые тестовые данные
        return [];
    }
}