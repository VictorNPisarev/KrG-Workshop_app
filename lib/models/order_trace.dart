import 'workplace_status.dart';

class OrderTrace {
  final String orderId;
  final String orderNumber;
  final DateTime readyDate;
  final List<WorkplaceStatus> workplaces;

  OrderTrace({
    required this.orderId,
    required this.orderNumber,
    required this.readyDate,
    required this.workplaces,
  });

  factory OrderTrace.fromJson(Map<String, dynamic> json) 
  {
    return OrderTrace(
      orderId: json['orderId'] as String,
      orderNumber: json['orderNumber'] as String,
      readyDate: DateTime.parse(json['readyDate'] as String),
      workplaces: (json['workplaces'] as List)
          .map((w) => WorkplaceStatus.fromJson(w))
          .toList(),
    );
  }
}