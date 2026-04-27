import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Workplace
{
	final String id;
	final String name;
	final bool isWorkPlace;

	String? previousWorkplace;
	String? nextWorkPlace;
	IconData workplaceIcon;
	
	Workplace({
		required this.id,
		required this.name,
		required this.previousWorkplace,
		required this.nextWorkPlace,
		required this.isWorkPlace,
		this.workplaceIcon = Icons.work,
	});
	
		// Фабричный конструктор для создания нового заказа
	factory Workplace.create({
		required String name,
		bool isWorkPlace = true,
		String? previousWorkPlace,
		String? nextWorkPlace
	})
	{
		final id = Uuid().v4(); // Генерация UUID
		return Workplace(
			id: id,
			name: name,
			isWorkPlace: isWorkPlace,
			previousWorkplace: previousWorkPlace,
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
			
			// Map для иконок
			final Map<String, IconData> workplaceIconsMapping = 
			{
				'Торцовка': Icons.carpenter,
				'Профилирование': Icons.border_inner,
				'Сборка': Icons.build,
				'Шлифовка': Icons.how_to_vote,
				'Покраска': Icons.brush,
				'Фурнитура': Icons.lock_open,
				'Остекление': Icons.aspect_ratio,
				'Упаковка': Icons.inventory_2,
			};

			final icon = workplaceIconsMapping[status] ?? Icons.work_outline;
			
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
				previousWorkplace: previous?.toString(),
				nextWorkPlace: null, // Пока нет в данных
				isWorkPlace: (isWorkplaceStr?.toString() ?? 'Нет').toLowerCase() == 'да',
				workplaceIcon: icon
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
			'previousWorkPlace': previousWorkplace,
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
			previousWorkplace: null,
			nextWorkPlace: null,
			isWorkPlace: true,
		);
	}

}