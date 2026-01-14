// lib/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/orderInProduct.dart';
import '../models/order.dart';
import '../models/workplace.dart';

class OrderDetailScreen extends StatefulWidget
{
    final OrderInProduct orderInProduct;
    final Workplace currentWorkplace;
    
    const OrderDetailScreen({
        super.key,
        required this.orderInProduct,
        required this.currentWorkplace,
    });
    
    @override
    State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
{
    late OrderInProduct _orderInProduct;
    
    @override
    void initState()
    {
        super.initState();
        _orderInProduct = widget.orderInProduct;
    }
    
    @override
    Widget build(BuildContext context)
    {
        final Order? order = _orderInProduct.order;
        final isCurrentOrder = _orderInProduct.status == OrderStatus.inProgress;
        final isPendingOrder = _orderInProduct.status == OrderStatus.pending;
        
        return Scaffold(
            appBar: AppBar(
                title: Text('Заказ #${order?.orderNumber ?? ''}'),
            ),
            body: Column(
                children: [
                    Expanded(
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    _buildInfoCard(),
                                    const SizedBox(height: 16),
                                    _buildStatusCard(),
                                    const SizedBox(height: 16),
                                    _buildProductDetailsCard(),
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
                                            onPressed: _takeToWork,
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
                                            onPressed: _completeOrder,
                                        ),
                                ],
                            ),
                        ),
                ],
            ),
        );
    }
    
    void _takeToWork()
    {
        // TODO: Реализовать взятие в работу
        print('Взять в работу заказ ${_orderInProduct.order?.orderNumber}');
        
        // Обновляем статус локально
        setState(()
        {
            _orderInProduct = _orderInProduct.copyWith(
                status: OrderStatus.inProgress,
                changeDate: DateTime.now(),
            );
        });
    }
    
    void _completeOrder()
    {
        // TODO: Реализовать завершение заказа
        print('Завершить заказ ${_orderInProduct.order?.orderNumber}');
        
        // Обновляем статус локально
        setState(()
        {
            _orderInProduct = _orderInProduct.copyWith(
                status: OrderStatus.completed,
                changeDate: DateTime.now(),
            );
        });
    }
    
    Widget _buildInfoCard()
    {
        final order = _orderInProduct.order;
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
                        _buildInfoRow('Номер заказа:', order?.orderNumber ?? ''),
                        _buildInfoRow('Срок исполнения:', 
                            order != null ? _formatDate(order!.readyDate) : ''),
                        _buildInfoRow('Количество окон:', 
                            order != null ? '${order?.winCount} шт' : ''),
                        _buildInfoRow('Площадь окон:', 
                            order != null ? '${order?.winArea} м²' : ''),
                        _buildInfoRow('Количество плит:', 
                            order != null ? '${order?.plateCount} шт' : ''),
                        _buildInfoRow('Площадь плит:', 
                            order != null ? '${order.plateArea} м²' : ''),
                        _buildInfoRow('Эконом:', order?.econom == true ? 'Да' : 'Нет'),
                        _buildInfoRow('Претензия:', order?.claim == true ? 'Да' : 'Нет'),
                        _buildInfoRow('Только оплаченные:', order?.onlyPayed == true ? 'Да' : 'Нет'),
                    ],
                ),
            ),
        );
    }
    
    Widget _buildStatusCard()
    {
        return Card(
            color: _getStatusColor(_orderInProduct.status).withOpacity(0.1),
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
                                        _orderInProduct.status.displayName,
                                        style: const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: _getStatusColor(_orderInProduct.status),
                                ),
                                const Spacer(),
                                Text(
                                    'Участок: ${_orderInProduct.workplaceId}',
                                    style: const TextStyle(color: Colors.grey),
                                ),
                            ],
                        ),
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                                'Изменен: ${_formatDate(_orderInProduct.changeDate)}',
                                style: const TextStyle(color: Colors.grey),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
    
    Widget _buildProductDetailsCard()
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
                        _buildInfoRow('Древесина:', _orderInProduct.lumber),
                        _buildInfoRow('Штапик:', _orderInProduct.glazingBead),
                        _buildInfoRow('Двусторонняя покраска:', 
                            _orderInProduct.twoSidePaint ? 'Да' : 'Нет'),
                        _buildInfoRow('Комментарий:', _orderInProduct.comment),
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