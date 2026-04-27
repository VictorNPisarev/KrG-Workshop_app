import 'workplace_status.dart';

class OrderTrace {
	final String orderId;
	final String productionOrderId;
	final String orderNumber;
	final DateTime readyDate;
	final List<WorkplaceStatus> workplaces;

	OrderTrace({
		required this.orderId,
		required this.productionOrderId,
		required this.orderNumber,
		required this.readyDate,
		required this.workplaces,
	});

	factory OrderTrace.fromJson(Map<String, dynamic> json) 
	{
		return OrderTrace(
			orderId: json['orderId'] as String,
			productionOrderId: json['productionOrderId'] as String,
			orderNumber: json['orderNumber'] as String,
			readyDate: DateTime.parse(json['readyDate'] as String),
			workplaces: (json['workplaces'] as List)
					.map((w) => WorkplaceStatus.fromJson(w))
					.toList(),
		);
	}

		// Проверить, можно ли взять заказ на текущий участок в обход
	bool canForceTake(String workplaceId) 
	{
		final workplace = workplaces.firstWhere(
			(w) => w.workplaceId == workplaceId,
			orElse: () => WorkplaceStatus(workplaceId: workplaceId, workplaceName: "", status: OrderStatus.notDefined),
		);
		// Не показываем кнопку, если заказ уже в работе или завершён на этом участке
		return workplace.status != OrderStatus.inProgress && workplace.status != OrderStatus.completed;
	}

}