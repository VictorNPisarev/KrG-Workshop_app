import 'package:workshop_app/models/workplace.dart';
import 'orderInProduct.dart';
import 'order.dart';
import 'package:uuid/uuid.dart';

class OriginalOrderInProduct
{
    //final String id = Uuid().v4();
    final String id;
    final String orderId;
    final String lumber; //тип и порода древесины
    final String glazingBead; //тип штапика (стандарт / рустикальный)
    final bool twoSidePaint; //отметка о двухсторонней покраске
    
    //TODO отдельная таблица OrderWorkplace
    String workplaceId; // TODO должна быть связь много ко многим, т.к. заказ может находиться одновременно на нескольких участках
    DateTime changeDate; // TODO не просто дата изменения этапа, а даты, когда участок взял заказ в работу и когда закончил его
    OrderStatus status; // TODO в ту же таблицу. А еще лучше просто динамически рассчитываемое поле исходя из предыдущих данных   


    String comment; //TODO отдельная таблица примечаний к заказу с привязками времени, сотрудника и участка (если необходимо)

    Order? order;
    Workplace? workplace;
    
    OriginalOrderInProduct({
        required this.id,
        required this.orderId,
        required this.workplaceId,
        required this.changeDate,
        required this.comment,
        required this.lumber,
        required this.glazingBead,
        required this.twoSidePaint,
        required this.status,
        this.order,
        this.workplace
    });
    
    // Метод для создания объекта из JSON (будет полезен позже)
    factory OriginalOrderInProduct.fromJson(Map<String, dynamic> json)
    {
        return OriginalOrderInProduct(
            id: json['id'] as String,
            orderId: json['orderId'] as String,
            workplaceId: json['workplaceId'] as String,
            changeDate: DateTime.parse(json['changeDate'] as String),
            comment: json['comment'] as String,
            lumber: json['lumber'] as String,
            glazingBead: json['glazingBead'] as String,
            twoSidePaint: json['twoSidePaint'] as bool,
            status: OrderStatus.values.firstWhere(
                (status) => status.name == json['status'],
                orElse: () => OrderStatus.pending,
            ),
            order: null,
            workplace: null
        );
    }
    
    // Метод для конвертации в JSON
    Map<String, dynamic> toJson()
    {
        return {
            'id': id,
            'orderId': orderId,
            'workplaceId': workplaceId,
            'changeDate': changeDate.toIso8601String(),
            'comment': comment,
            'lumber': lumber,
            'glazingBead': glazingBead,
            'twoSidePaint': twoSidePaint,
            'status': status,
        };
    }

        // Добавляем метод для создания копии с обновленным order
    OriginalOrderInProduct copyWith({
        String? id,
        String? orderId,
        String? workplaceId,
        DateTime? changeDate,
        String? comment,
        String? lumber,
        String? glazingBead,
        bool? twoSidePaint,
        OrderStatus? status,
        Order? order,
        Workplace? workplace
    })
    {
        return OriginalOrderInProduct(
            id: id ?? this.id,
            orderId: orderId ?? this.orderId,
            workplaceId: workplaceId ?? this.workplaceId,
            changeDate: changeDate ?? this.changeDate,
            comment: comment ?? this.comment,
            lumber: lumber ?? this.lumber,
            glazingBead: glazingBead ?? this.glazingBead,
            twoSidePaint: twoSidePaint ?? this.twoSidePaint,
            status: status ?? this.status,
            order: order ?? this.order,
            workplace: workplace ?? this.workplace,
        );
    }

        // Метод для проверки, находится ли заказ на текущем участке
    bool isInWorkplace(String workplaceId)
    {
        return this.workplaceId == workplaceId;
    }
    
    // Метод для проверки, ожидает ли заказ на предыдущем участке
/*    bool isPendingInWorkplace(String workplaceId)
    {
        return workplaceId?.id == workshopId && status == OrderStatus.pending;
    }
*/

        // Упрощенный конструктор для mock-данных
    factory OriginalOrderInProduct.simple({
        required String orderId,
        required String workplaceId,
        required OrderStatus status,
        String comment = '',
        String lumber = '',
        String glazingBead = '',
        bool twoSidePaint = false,
        Order? order = null
    })
    {
        return OriginalOrderInProduct(
            id: Uuid().v4(),
            orderId: orderId,
            workplaceId: workplaceId,
            changeDate: DateTime.now(),
            comment: comment,
            lumber: lumber,
            glazingBead: glazingBead,
            twoSidePaint: twoSidePaint,
            status: status,
            order: order
        );
    }

}

// Перечисление статусов заказа
/*enum OrderStatus
{
    pending('Ожидает'),
    inProgress('В работе'),
    completed('Завершен');
    
    final String displayName;
    
    const OrderStatus(this.displayName);
}*/