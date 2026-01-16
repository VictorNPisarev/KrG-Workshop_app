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
        try
        {
            print('🧩 Начало парсинга Workplace');
            print('   Сырой JSON: $json');
            
            // Дебаг каждого поля
            final rowId = json['Row ID'];
            print('   Row ID: $rowId (тип: ${rowId.runtimeType})');
            
            final status = json['Статус'];
            print('   Статус: $status (тип: ${status.runtimeType})');
            
            final previous = json['Предыдущий участок'];
            print('   Предыдущий участок: $previous (тип: ${previous.runtimeType})');
            
            final isWorkplaceStr = json['Участок производства'];
            print('   Участок производства: $isWorkplaceStr (тип: ${isWorkplaceStr.runtimeType})');
            
            // Валидация
            if (rowId == null)
            {
                throw Exception('❌ Row ID не может быть null');
            }
            
            if (status == null)
            {
                throw Exception('❌ Статус не может быть null');
            }
            
            return Workplace(
                id: rowId.toString(),
                name: status.toString(),
                previousWorkPlace: previous?.toString(),
                nextWorkPlace: null, // Пока нет в данных
                isWorkPlace: (isWorkplaceStr?.toString() ?? 'Нет').toLowerCase() == 'да',
            );
        }
        catch (e)
        {
            print('❌ Ошибка при парсинге Workplace: $e');
            print('   Проблемный JSON: $json');
            rethrow;
        }
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

    // Fallback конструктор на случай ошибок
    factory Workplace.fallback({int index = 0})
    {
        return Workplace(
            id: 'fallback_$index',
            name: 'Участок $index (ошибка загрузки)',
            previousWorkPlace: null,
            nextWorkPlace: null,
            isWorkPlace: true,
        );
    }

}