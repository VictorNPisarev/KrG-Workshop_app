import 'package:uuid/uuid.dart';

class Workplace
{
    final String id;
    final String name;
    final bool isWorkPlace;

    String? previousWorkPlace;
    String? nextWorkPlace;
    
    Workplace({
        required this.id,
        required this.name,
        required this.previousWorkPlace,
        required this.nextWorkPlace,
        required this.isWorkPlace,
    });
    
        // Фабричный конструктор для создания нового заказа
    factory Workplace.create({
        required String name,
        bool isWorkPlace = true,
        String? previousWorkPlace = null,
        String? nextWorkPlace = null
    })
    {
        final id = Uuid().v4(); // Генерация UUID
        return Workplace(
            id: id,
            name: name,
            isWorkPlace: isWorkPlace,
            previousWorkPlace: previousWorkPlace,
            nextWorkPlace: nextWorkPlace
        );
    }

    factory Workplace.fromJson(Map<String, dynamic> json)
    {
        return Workplace(
            id: json['id'] as String,
            name: json['name'] as String,
            previousWorkPlace: json['previousWorkPlace'] as String,
            nextWorkPlace: json['nextWorkPlace'] as String,
            isWorkPlace: json['isWorkPlace'] as bool,
        );
    }
    
    Map<String, dynamic> toJson()
    {
        return {
            'id': id,
            'name': name,
            'previousWorkPlace': previousWorkPlace,
            'nextWorkPlace': nextWorkPlace,
            'isWorkPlace': isWorkPlace,
        };
    }
}