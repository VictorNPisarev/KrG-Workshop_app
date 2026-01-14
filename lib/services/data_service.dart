// lib/services/data_service.dart
import 'package:workshop_app/models/orderInProduct.dart';

import '../models/workplace.dart';
import '../models/order.dart';

class DataService
{
    // Mock-данные: список участков
    static final List<Workplace> Workplaces = [
        Workplace(id: '1', name: 'Торцовка', previousWorkPlace: null, nextWorkPlace: '2', isWorkPlace: true),
        Workplace(id: '2', name: 'Профилирование', previousWorkPlace: '1', nextWorkPlace: '3', isWorkPlace: true),
        Workplace(id: '3', name: 'Шлифовка', previousWorkPlace: '2', nextWorkPlace: '4', isWorkPlace: true),
        Workplace(id: '4', name: 'Покраска', previousWorkPlace: '3', nextWorkPlace: '5', isWorkPlace: true),
        Workplace(id: '5', name: 'Фурнитура', previousWorkPlace: '4', nextWorkPlace: '6', isWorkPlace: true),
        Workplace(id: '6', name: 'Остекление', previousWorkPlace: '5', nextWorkPlace: '7', isWorkPlace: true),
        Workplace(id: '7', name: 'Упаковка', previousWorkPlace: '6', nextWorkPlace: '8', isWorkPlace: true),
        Workplace(id: '8', name: 'Готово', previousWorkPlace: '7', nextWorkPlace: null, isWorkPlace: true),
    ];
    
    // Mock-данные: список заказов
    static final List<Order> orders = [
        Order.simple(
            orderNumber: '2024-001',
            readyDate: DateTime.now(),
            winCount: 5,
            winArea: 8
        ),
        Order.simple(
            orderNumber: '2024-002',
            readyDate: DateTime.now(),
            winCount: 4,
            winArea: 8,
            plateCount: 10,
            plateArea: 3
        ),
        Order.simple(
            orderNumber: '2024-003',
            readyDate: DateTime.now(),
            claim: true
        ),
        Order.simple(
            orderNumber: '2024-004',
            readyDate: DateTime.now(),
            winCount: 2,
            winArea: 5
        ),
        Order.simple(
            orderNumber: '2024-005',
            readyDate: DateTime.now(),
            winCount: 6,
            winArea: 7,
            econom: true
        ),
    ];
    
        // Mock-данные: список заказов на производстве
    static final List<OrderInProduct> ordersInProduct = [
        OrderInProduct.simple(
            orderId: orders[0].id,
            workplaceId: '3',
            status: OrderStatus.pending,
            order: orders[0]
        ),
        OrderInProduct.simple(
            orderId: orders[1].id,
            workplaceId: '3',
            status: OrderStatus.inProgress,
            order: orders[1]
        ),
        OrderInProduct.simple(
            orderId: orders[2].id,
            workplaceId: '3',
            status: OrderStatus.pending,
            order: orders[2]
        ),
        OrderInProduct.simple(
            orderId: orders[3].id,
            workplaceId: '2',
            status: OrderStatus.pending,
            twoSidePaint: true,
            order: orders[3]
        ),
        OrderInProduct.simple(
            orderId: orders[4].id,
            workplaceId: '1',
            status: OrderStatus.inProgress,
            order: orders[4]
        ),
    ];

    // Получить заказы для текущего участка
    static List<OrderInProduct> getCurrentOrders(String workplaceId)
    {
        return ordersInProduct.where((order) => order.isInWorkplace(workplaceId)).toList();
    }
    
    // Получить заказы, ожидающие на предыдущем участке
    static List<OrderInProduct> getPendingOrders(String workplaceId)
    {
        Workplace? workplace = getWorkplaceById(workplaceId);
        String? previousWorkplace = workplace!.previousWorkPlace;

        if (previousWorkplace == null)
        {
          return List.empty();
        }

        return ordersInProduct.where((order) => order.isInWorkplace(previousWorkplace)).toList();//order.isPendingInWorkplace(WorkplaceId)).toList();
    }
    
    // Найти участок по ID
    static Workplace? getWorkplaceById(String id)
    {
        return Workplaces.firstWhere((Workplace) => Workplace.id == id);
    }
}
