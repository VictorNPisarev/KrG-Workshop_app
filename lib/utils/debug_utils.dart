// Создадим файл lib/utils/debug_utils.dart
import 'dart:convert';

import '../models/order_in_product.dart';

class DebugUtils
{
    static void logApiCall(String method, dynamic request, dynamic response)
    {
        print('🌐 API Call: $method');
        print('📤 Request: ${jsonEncode(request)}');
        print('📥 Response: ${jsonEncode(response)}');
        print('⏰ Time: ${DateTime.now()}');
        print('─' * 50);
    }
    
    static void logOrderUpdate(OrderInProduct order, String action)
    {
        print('🔄 Order Update: $action');
        print('   Order #${order.orderNumber}');
        print('   Status: ${order.status.name}');
        print('   Workplace: ${order.workplaceId}');
        print('─' * 50);
    }
}