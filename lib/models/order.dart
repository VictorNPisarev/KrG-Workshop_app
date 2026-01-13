class Order
{
    final int id;
    final String orderNumber;
    final DateTime readyDate;
    final int winCount;
    final double winArea;
    final int plateCount;
    final double plateArea;
    final bool econom;
    final bool claim;
    final bool onlyPayed;
    
    Order({
        required this.id,
        required this.orderNumber,
        required this.readyDate,
        required this.winCount,
        required this.winArea,
        required this.plateCount,
        required this.plateArea,
        required this.econom,
        required this.claim,
        required this.onlyPayed,
    });
    
    // Метод для создания объекта из JSON (будет полезен позже)
    factory Order.fromJson(Map<String, dynamic> json)
    {
        /*return Order(
            id: json['id'] as int,
            orderNumber: json['orderNumber'] as String,
            customerName: json['customerName'] as String,
            deadline: DateTime.parse(json['deadline'] as String),
            currentStage: json['currentStage'] as String,
            status: OrderStatus.values.firstWhere(
                (status) => status.name == json['status'],
                orElse: () => OrderStatus.pending,
            ),
        );*/

        return Order(
            id: json['id'] as int,
            orderNumber: json['orderNumber'] as String,
            readyDate: DateTime.parse(json['deadline'] as String),
            winCount: json['winAmount'] as int,
            winArea: json['winSqrt'] as double,
            plateCount: json['plateAmount'] as int,
            plateArea: json['plateSqrt'] as double,
            econom: json['econom'] as bool,
            claim: json['claim'] as bool,
            onlyPayed: json['onlyPayed'] as bool,
        );
    }
    
    // Метод для конвертации в JSON
    Map<String, dynamic> toJson()
    {
        return {
            'id': id,
            'orderNumber': orderNumber,
            'readyDate': readyDate.toIso8601String(),
            'winCount': winCount,
            'winArea': winArea,
            'plateCount': plateCount,
            'plateArea': plateArea,
            'econom': econom,
            'claim': claim,
            'onlyPayed': onlyPayed,
        };
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