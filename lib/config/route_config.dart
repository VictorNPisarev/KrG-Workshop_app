// lib/config/route_config.dart
import 'package:flutter/foundation.dart';

class RouteConfig
{
	// Базовый URL для Node.js API
	static const String nodeBaseUrl = '/api';
	
	// Сопоставление action -> REST URL (с плейсхолдерами)
	static const Map<String, String> routeMap =
	{
		// GET запросы
		'getPendingOrdersByWorkplace': '/orders/pending',
		'getActiveOrdersByWorkplace': '/orders/active',
		'getActiveAndPendingOrdersByWorkplace': '/orders/in-work',
		'getOrderTrace': '/orders/:orderNumber/trace',
		'getUserByEmail': '/users/by-email/:email',
		'getUserWorkplaces': '/users/:userId/workplaces',
		'getWorkplaces': '/workplaces',
		
		// POST запросы
		'updateOrderWorkplace': '/operations/start',
		'completeOrderWorkplace': '/operations/complete',
	};
	
	// Преобразует URL с плейсхолдерами в реальный URL
	static String buildUrl(String action, {Map<String, dynamic>? params})
	{
		final template = routeMap[action];
		if (template == null)
		{
			throw Exception('Unknown action: $action');
		}
		
		var url = template;
		
		// Заменяем плейсхолдеры :param на значения из params
		// а оставшиеся параметры добавляем как query string
		final remainingParams = <String, String>{};

		params?.forEach((key, value)
		{
			final placeholder = ':$key';
			
			if (url.contains(placeholder))
			{
				url = url.replaceAll(placeholder, value.toString());
			}
			else
			{
				remainingParams[key] = value.toString();
			}
	
		});
		
		if (remainingParams.isNotEmpty && !isPostAction(action))
		{
			final queryString = remainingParams.entries
					.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
					.join('&');
			url += '?$queryString';
		}
		
		return url;
	}
	
	// Проверяет, должен ли запрос быть POST
	static bool isPostAction(String action)
	{
		const postActions = [
			'updateOrderWorkplace',
			'completeOrderWorkplace',
		];
		return postActions.contains(action);
	}
}