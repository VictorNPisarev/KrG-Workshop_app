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
    
    // НОВОЕ ПОЛЕ: операции по заказу
    OrderOperations operations;

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
        required this.operations,
        this.status = OrderStatus.pending,
    });
    
    factory OrderInProduct.fromJson(Map<String, dynamic> json)
    {
        // Парсим операции
        final operationsJson = json['operations'] ?? {};
        final orderOperations = OrderOperations.fromJson(
          operationsJson is Map<String, dynamic> 
            ? operationsJson 
            : {}
        );
        
        // Определяем статус на основе операций
        OrderStatus determineStatus(Map<String, dynamic> json, OrderOperations ops) 
        {
          // Если заказ завершен по операциям
          if (ops.isCompleted) 
          {
            return OrderStatus.completed;
          }
          // Если заказ начат по операциям
          else if (ops.isStarted) 
          {
            return OrderStatus.inProgress;
          }
          // Иначе ожидает
          else 
          {
            return OrderStatus.pending;
          }
        }
        
        final status = determineStatus(json, orderOperations);

        // Оптимизация 1: Используем локальные переменные для часто используемых полей
        final rowId = json['Row ID'];
        final deadline = json['Deadline'] as String?;
        final changeDateStr = json['Дата изменения'] as String?;
        
        // Оптимизация 2: Отложенный парсинг дат (parse только если нужно)
        DateTime parseDate(String? dateStr) {
            if (dateStr == null || dateStr.isEmpty) return DateTime.now();
            try {
                return DateTime.parse(dateStr);
            } catch (e) {
                print('⚠️ Ошибка парсинга даты: $dateStr');
                return DateTime.now();
            }
        }
        
        return OrderInProduct(
            id: rowId?.toString() ?? '',
            orderId: json['ID заказа']?.toString() ?? '',
            orderNumber: json['Name']?.toString() ?? '',
            readyDate: parseDate(deadline),
            winCount: (json['WindowCount'] ?? 0) as int,
            winArea: (json['WindowArea'] ?? 0.0).toDouble(),
            plateCount: (json['PlateCount'] ?? 0) as int,
            plateArea: (json['PlateArea'] ?? 0.0).toDouble(),
            econom: (json['Econom'] ?? false) as bool,
            claim: (json['Claim'] ?? false) as bool,
            onlyPayed: (json['OnlyPayed'] ?? false) as bool,
            lumber: json['Брус']?.toString() ?? '',
            glazingBead: json['Штапик']?.toString() ?? '',
            twoSidePaint: (json['Двухсторонняя покраска'] == "Да"),
            workplaceId: json['ID статуса']?.toString() ?? '',
            changeDate: parseDate(changeDateStr),
            comment: json['Примечания']?.toString() ?? '',
            operations: orderOperations,
            status: status,

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
        OrderOperations? operations,
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
            operations: operations ?? this.operations,
            status: status ?? this.status,
        );
    }

    // Метод для проверки, находится ли заказ на текущем участке
    bool isInWorkplace(String workplaceId)
    {
        return this.workplaceId == workplaceId;
    }

    /*void setStatusByWorkplace (String workplaceId)
    {
        status = isInWorkplace(workplaceId) ? OrderStatus.inProgress : OrderStatus.pending;
    }*/

    void setStatusByWorkplace(String workplaceId) 
    {
      //Поддержка старых заказов, для которых нет записей в таблице движения заказа
      if(operations.operationsCount == 0)
      {
        status = isInWorkplace(workplaceId) ? OrderStatus.inProgress : OrderStatus.pending;
        return;
      }

      // Для заказов на предыдущем участке все гда вывожу статус "Ожидание"
      if (!isInWorkplace(workplaceId))
      {
        status = OrderStatus.pending;
        return;
      }

      // Теперь используем данные из operations для определения статуса
      if (operations.isCompleted) 
      {
        status = OrderStatus.completed;
      } 
      else if (isInWorkplace(workplaceId) && operations.isStarted) 
      {
        status = OrderStatus.inProgress;
      } 
      else 
      {
        status = OrderStatus.pending;
      }
    }
    
    // НОВЫЙ МЕТОД: проверка, можно ли взять заказ в работу
    bool get canBeTakenToWork 
    {
      // Заказ можно взять в работу если:
      // 1. Он не завершен
      // 2. Он еще не начат (или начат, но не на текущем участке)
      return !operations.isCompleted;
    }
    
    // НОВЫЙ МЕТОД: проверка, можно ли завершить заказ
    bool get canBeCompleted 
    {
      // Заказ можно завершить если:
      // 1. Он начат
      // 2. Он не завершен
      return operations.isStarted && !operations.isCompleted;
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

// ДОБАВИМ НОВЫЙ КЛАСС ДЛЯ ОПЕРАЦИЙ
class OrderOperations 
{
  final bool isStarted;
  final bool isCompleted;
  final DateTime? startDateTime;
  final DateTime? completeDateTime;
  final int operationsCount;
  
  OrderOperations({
    required this.isStarted,
    required this.isCompleted,
    this.startDateTime,
    this.completeDateTime,
    required this.operationsCount,
  });
  
  factory OrderOperations.fromJson(Map<String, dynamic> json) 
  {
    return OrderOperations(
      isStarted: json['isStarted'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      startDateTime: json['startDateTime'] != null 
          ? DateTime.parse(json['startDateTime']) 
          : null,
      completeDateTime: json['completeDateTime'] != null 
          ? DateTime.parse(json['completeDateTime']) 
          : null,
      operationsCount: json['operationsCount'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() 
  {
    return {
      'isStarted': isStarted,
      'isCompleted': isCompleted,
      'startDateTime': startDateTime?.toIso8601String(),
      'completeDateTime': completeDateTime?.toIso8601String(),
      'operationsCount': operationsCount,
    };
  }
}