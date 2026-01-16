import 'package:intl/intl.dart';
class OrderInProduct
{
    final String id;
    final String orderId;
    final String lumber;
    final String glazingBead;
    final bool twoSidePaint;
    
    // Поля из Orders
    final String orderNumber;
    final DateTime readyDate;
    final int winCount;
    final double winArea;
    final int plateCount;
    final double plateArea;
    final bool econom;
    final bool claim;
    final bool onlyPayed;
    
    // Поля статуса
    String workplaceId;
    DateTime changeDate;
    OrderStatus status;
    String comment;
    
    OrderInProduct({
        required this.id,
        required this.orderId,
        required this.orderNumber,
        required this.readyDate,
        required this.winCount,
        required this.winArea,
        required this.plateCount,
        required this.plateArea,
        required this.econom,
        required this.claim,
        required this.onlyPayed,
        required this.lumber,
        required this.glazingBead,
        required this.twoSidePaint,
        required this.workplaceId,
        required this.changeDate,
        required this.comment,
        this.status = OrderStatus.pending,
    });
    
    factory OrderInProduct.fromJson(Map<String, dynamic> json)
    {
        return OrderInProduct(
            id: json['Row ID']?.toString() ?? '',
            orderId: json['ID заказа']?.toString() ?? '',
            orderNumber: json['Name']?.toString() ?? '',
            readyDate: DateTime.parse((json['Deadline'] as String).replaceAll('/', '.')),
            winCount: (json['WindowCount'] ?? 0) as int,
            winArea: (json['WindowArea'] ?? 0.0).toDouble(),
            plateCount: (json['PlateCount'] ?? 0) as int,
            plateArea: (json['PlateArea'] ?? 0.0).toDouble(),
            econom: (json['Econom'] == "Да"),
            claim: (json['Claim'] == "Да"),
            onlyPayed: (json['onlyPayed'] == "Да"),
            lumber: json['Брус']?.toString() ?? '',
            glazingBead: json['Штапик']?.toString() ?? '',
            twoSidePaint: (json['Двухсторонняя покраска'] == "Да"),
            workplaceId: json['ID статуса']?.toString() ?? '',
            changeDate: DateTime.parse((json['Дата изменения'] as String).replaceAll('/', '.')),
            comment: json['Примечания']?.toString() ?? ''
        );
    }
    
    static OrderStatus _parseStatus(dynamic status)
    {
        final statusStr = status?.toString().toLowerCase() ?? '';
        if (statusStr.contains('progress')) return OrderStatus.inProgress;
        if (statusStr.contains('complete')) return OrderStatus.completed;
        return OrderStatus.pending;
    }
    
    OrderInProduct copyWith({
        String? id,
        String? orderId,
        String? orderNumber,
        String? customerName,
        DateTime? readyDate,
        int? winCount,
        double? winArea,
        int? plateCount,
        double? plateArea,
        bool? econom,
        bool? claim,
        bool? onlyPayed,
        String? lumber,
        String? glazingBead,
        bool? twoSidePaint,
        String? workplaceId,
        DateTime? changeDate,
        String? comment,
        OrderStatus? status,
    })
    {
        return OrderInProduct(
            id: id ?? this.id,
            orderId: orderId ?? this.orderId,
            orderNumber: orderNumber ?? this.orderNumber,
            readyDate: readyDate ?? this.readyDate,
            winCount: winCount ?? this.winCount,
            winArea: winArea ?? this.winArea,
            plateCount: plateCount ?? this.plateCount,
            plateArea: plateArea ?? this.plateArea,
            econom: econom ?? this.econom,
            claim: claim ?? this.claim,
            onlyPayed: onlyPayed ?? this.onlyPayed,
            lumber: lumber ?? this.lumber,
            glazingBead: glazingBead ?? this.glazingBead,
            twoSidePaint: twoSidePaint ?? this.twoSidePaint,
            workplaceId: workplaceId ?? this.workplaceId,
            changeDate: changeDate ?? this.changeDate,
            comment: comment ?? this.comment,
            status: status ?? this.status,
        );
    }

    // Метод для проверки, находится ли заказ на текущем участке
    bool isInWorkplace(String workplaceId)
    {
        return this.workplaceId == workplaceId;
    }
}

// Перечисление статусов заказа
enum OrderStatus
{
    pending('Ожидает'),
    inProgress('В работе'),
    completed('Завершен');
    
    final String displayName;
    
    const OrderStatus(this.displayName);
}