import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/orderInProduct.dart';
import '../models/workplace.dart';
import '../providers/orders_provider.dart';

class OrderDetailScreen extends StatefulWidget
{
    final String orderId; // Принимаем только ID вместо всего объекта
    final Workplace currentWorkplace;
    
    const OrderDetailScreen({
        super.key,
        required this.orderId,
        required this.currentWorkplace,
    });
    
    @override
    State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
{
    OrderInProduct? _currentOrder;
    
    @override
    void didChangeDependencies()
    {
        super.didChangeDependencies();
        _loadCurrentOrder();
    }
    
    void _loadCurrentOrder()
    {
        final provider = Provider.of<OrdersProvider>(context, listen: false);
        final order = provider.getOrderById(widget.orderId);
        
        if (order != null && ( _currentOrder == null || _currentOrder!.id != order.id))
        {
            setState(()
            {
                _currentOrder = order;
            });
        }
    }
    
    @override
    Widget build(BuildContext context)
    {
        // Получаем актуальную версию заказа при каждом build
        final provider = context.watch<OrdersProvider>();
        final currentOrder = provider.getOrderById(widget.orderId) ?? _currentOrder;
        
        if (currentOrder == null)
        {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
            );
        }
        
        final isCurrentOrder = currentOrder.status == OrderStatus.inProgress;
        final isPendingOrder = currentOrder.status == OrderStatus.pending;
        
        return Scaffold(
            appBar: AppBar(
                title: Row(
                    children: [
                        Text('Заказ #${currentOrder.orderNumber}'),
                        const SizedBox(width: 8),
                        // Иконки флагов
                        if (currentOrder.econom)
                            Tooltip(
                                message: 'Эконом-заказ',
                                child: Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                        Icons.attach_money,
                                        color: Colors.orange,
                                        size: 20,
                                    ),
                                ),
                            ),
                        if (currentOrder.claim)
                            Tooltip(
                                message: 'Есть претензия',
                                child: Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                        Icons.warning,
                                        color: Colors.red,
                                        size: 20,
                                    ),
                                ),
                            ),
                        if (currentOrder.onlyPayed)
                            Tooltip(
                                message: 'Оплачен полностью',
                                child: Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                        Icons.payment,
                                        color: Colors.green,
                                        size: 20,
                                    ),
                                ),
                            ),
                    ],
                ),
                actions: [
                    // Можно также добавить в actions для более стандартного отображения
                    if (currentOrder.econom || currentOrder.claim || currentOrder.onlyPayed)
                        Tooltip(
                            message: 'Особые отметки заказа',
                            child: Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade300,
                            ),
                        ),
                ],
            ),  
            body: Column(
                children: [
                    Expanded(
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    _buildInfoCard(currentOrder),
                                    const SizedBox(height: 16),
                                    _buildStatusCard(currentOrder),
                                    const SizedBox(height: 16),
                                    _buildProductDetailsCard(currentOrder),
                                ],
                            ),
                        ),
                    ),
                    // Кнопки действий
                    if (isCurrentOrder || isPendingOrder)
                        Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.grey[100],
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                    if (isPendingOrder)
                                        ElevatedButton.icon(
                                            icon: const Icon(Icons.play_arrow),
                                            label: const Text('Взять в работу'),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                            ),
                                            onPressed: () => _takeToWork(context, currentOrder),
                                        ),
                                    if (isPendingOrder && isCurrentOrder)
                                        const SizedBox(width: 16),
                                    if (isCurrentOrder)
                                        ElevatedButton.icon(
                                            icon: const Icon(Icons.check),
                                            label: const Text('Завершить'),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                            ),
                                            onPressed: () => _completeOrder(context, currentOrder),
                                        ),
                                ],
                            ),
                        ),
                ],
            ),
        );
    }
    
    void _takeToWork(BuildContext context, OrderInProduct order)
    {
        final provider = context.read<OrdersProvider>();
        provider.takeOrderToWork(order);
    }
    
    void _completeOrder(BuildContext context, OrderInProduct order)
    {
        final provider = context.read<OrdersProvider>();
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Завершить заказ?'),
                content: Text(
                    'Вы уверены, что хотите завершить заказ ${order.orderNumber}?',
                ),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                    ),
                    ElevatedButton(
                        onPressed: ()
                        {
                            provider.completeOrder(order);
                            Navigator.pop(context); // Закрыть диалог
                            Navigator.pop(context); // Закрыть экран деталей
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                        ),
                        child: const Text('Завершить'),
                    ),
                ],
            ),
        );
    }
    
    Widget _buildInfoCard(OrderInProduct order)
    {
        return Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text(
                            'Основная информация',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                        const Divider(),
                        _buildInfoRow('Номер заказа:', order.orderNumber),
                        _buildInfoRow('Срок исполнения:', _formatDate(order.readyDate)),
                        _buildInfoRow('Количество окон:', '${order.winCount} шт'),
                        _buildInfoRow('Площадь окон:', '${order.winArea} м²'),
                        _buildInfoRow('Количество плит:', '${order.plateCount} шт'),
                        _buildInfoRow('Площадь плит:', '${order.plateArea} м²'),
                        _buildConditionalInfoRow('Эконом:', order.econom, 'Эконом-заказ', Colors.orange),
                        _buildConditionalInfoRow('Претензия:', order.claim, 'Претензия!', Colors.red),
                        _buildConditionalInfoRow('Только оплаченные:', order.onlyPayed, 'Оплачен полностью', Colors.green),                    ],
                ),
            ),
        );
    }
    
    Widget _buildStatusCard(OrderInProduct orderInProduct)
    {
        return Card(
            color: _getStatusColor(orderInProduct.status).withOpacity(0.1),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text(
                            'Статус заказа',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                        const Divider(),
                        Row(
                            children: [
                                Chip(
                                    label: Text(
                                        orderInProduct.status.displayName,
                                        style: const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: _getStatusColor(orderInProduct.status),
                                ),
                                const Spacer(),
                                Text(
                                    'Участок: ${orderInProduct.workplaceId}',
                                    style: const TextStyle(color: Colors.grey),
                                ),
                            ],
                        ),
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                                'Изменен: ${_formatDate(orderInProduct.changeDate)}',
                                style: const TextStyle(color: Colors.grey),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
    
    Widget _buildProductDetailsCard(OrderInProduct orderInProduct)
    {
        return Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text(
                            'Детали производства',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                        const Divider(),
                        _buildInfoRow('Древесина:', orderInProduct.lumber),
                        _buildInfoRow('Штапик:', orderInProduct.glazingBead),
                        _buildInfoRow('Двусторонняя покраска:', 
                            orderInProduct.twoSidePaint ? 'Да' : 'Нет'),
                        _buildInfoRow('Комментарий:', orderInProduct.comment),
                    ],
                ),
            ),
        );
    }
    
    Widget _buildInfoRow(String label, String value)
    {
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    SizedBox(
                        width: 150,
                        child: Text(
                            label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                            ),
                        ),
                    ),
                    Expanded(
                        child: Text(
                            value,
                            style: const TextStyle(fontSize: 16),
                        ),
                    ),
                ],
            ),
        );
    }

    Widget _buildConditionalInfoRow(String label, bool condition, String trueText, [Color? color])
    {
        if (!condition) return const SizedBox.shrink(); // Не показываем если "Нет"
        
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    SizedBox(
                        width: 150,
                        child: Text(
                            label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                            ),
                        ),
                    ),
                    Expanded(
                        child: Text(
                            trueText,
                            style: TextStyle(
                                fontSize: 16,
                                color: color ?? Colors.green, // Зеленый для положительных
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                    ),
                ],
            ),
        );
    }

    
    String _formatDate(DateTime date)
    {
        return '${date.day.toString().padLeft(2, '0')}.'
               '${date.month.toString().padLeft(2, '0')}.'
               '${date.year}';
    }
    
    Color _getStatusColor(OrderStatus status)
    {
        switch (status)
        {
            case OrderStatus.pending:
                return Colors.orange;
            case OrderStatus.inProgress:
                return Colors.blue;
            case OrderStatus.completed:
                return Colors.green;
        }
    }
}