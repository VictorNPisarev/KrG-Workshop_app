import 'package:flutter/material.dart';

class WorkplaceStatus 
{
	final String workplaceId;
	final String workplaceName;
	final OrderStatus status; // 'planned', 'active', 'completed'

	WorkplaceStatus({
		required this.workplaceId,
		required this.workplaceName,
		required this.status,
	});

	factory WorkplaceStatus.fromJson(Map<String, dynamic> json) 
	{
		return WorkplaceStatus
		(
			workplaceId:  json['id'] as String,
			workplaceName: json['name'] as String,
			status: determineStatus(json['status']),
		);
	}

	Color get statusColor 
	{
		switch (status) 
		{
			case OrderStatus.completed:
				return Colors.green;
			case OrderStatus.inProgress:
				return Colors.blue;
			case OrderStatus.pending:
				return Colors.orange;
			default:
				return Colors.grey;
		}
	}

	IconData get statusIcon 
	{
		switch (status) 
		{
			case OrderStatus.completed:
				return Icons.check_circle;
			case OrderStatus.inProgress:
				return Icons.play_circle;
			case OrderStatus.pending:
				return Icons.timer;
			default:
				return Icons.pending;
		}
	}

	static OrderStatus determineStatus(String serverStatus) 
	{
		// Если заказ завершен
		if (serverStatus == 'completed') 
		{
			return OrderStatus.completed;
		}
		// Если заказ начат по операциям
		if (serverStatus == 'active') 
		{
			return OrderStatus.inProgress;
		}
		// Иначе ожидает
		else if (serverStatus == 'pending' || serverStatus == 'joinery')
		{
			return OrderStatus.pending;
		}
		else
		{
			return OrderStatus.notDefined;
		}
	}
}

	// Перечисление статусов заказа
enum OrderStatus
{
	pending('Ожидает'),
	inProgress('В работе'),
	completed('Завершен'),
	notDefined('Не определен');
	
	final String displayName;
	
	const OrderStatus(this.displayName);
}
