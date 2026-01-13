import 'package:uuid/uuid.dart';
class Order
{
    //final String id = Uuid().v4();
    final String id;
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
        return Order(
            id: json['id'] as String,
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

    // Упрощенный конструктор для mock-данных
    factory Order.simple({
        required String orderNumber,
        required DateTime readyDate,
        int winCount = 0,
        double winArea = 0,
        int plateCount = 0,
        double plateArea = 0,
        bool econom = false,
        bool claim = false,
        bool onlyPayed = false
    })
    {
        return Order(
            id: Uuid().v4(),
            orderNumber: orderNumber,
            readyDate: DateTime.now().add(const Duration(days: 7)),
            winCount: winCount,
            winArea: winArea,
            plateCount: plateCount,
            plateArea: plateArea,
            econom: econom,
            claim: claim,
            onlyPayed: onlyPayed,
        );
    }

}
