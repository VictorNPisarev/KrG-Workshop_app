import 'package:flutter/material.dart';
import 'package:workshop_app/models/orderInProduct.dart';
import '../models/order.dart';

class OrderCard extends StatelessWidget
{
    final OrderInProduct orderInProduct;
    final VoidCallback? onCompletePressed;
    final VoidCallback? onStartPressed;
    final bool showCompleteButton;
    final bool showStartButton;
    
    const OrderCard({
        super.key,
        required this.orderInProduct,
        this.onCompletePressed,
        this.onStartPressed,
        this.showCompleteButton = false,
        this.showStartButton = false,
    });
    
    @override
    Widget build(BuildContext context)
    {
        return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
            ),
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // Заголовок с номером заказа и статусом
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Text(
                                    'Заказ #${orderInProduct.orderNumber}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                    ),
                                ),
                                _buildStatusChip(orderInProduct.status),
                            ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Информация о заказе
                        Text('Срок: ${_formatDate(orderInProduct.readyDate)}'),
                        Text('Окна: ${orderInProduct.winCount}'),
                        Text('Щитовые: ${orderInProduct.plateCount}'),
                        
                        // Кнопки действий (если нужны)
                        if (showCompleteButton || showStartButton)
                            _buildActionButtons(),
                    ],
                ),
            ),
        );
    }
    
    Widget _buildStatusChip(OrderStatus status)
    {
        Color chipColor;
        
        switch (status)
        {
            case OrderStatus.pending:
                chipColor = Colors.orange;
                break;
            case OrderStatus.inProgress:
                chipColor = Colors.blue;
                break;
            case OrderStatus.completed:
                chipColor = Colors.green;
                break;
        }
        
        return Chip(
            label: Text(
                status.displayName,
                style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: chipColor,
        );
    }
    
    Widget _buildActionButtons()
    {
        return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                    if (showStartButton)
                        ElevatedButton.icon(
                            onPressed: onStartPressed,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Взять в работу'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                            ),
                        ),
                    if (showCompleteButton && showStartButton)
                        const SizedBox(width: 8),
                    if (showCompleteButton)
                        ElevatedButton.icon(
                            onPressed: onCompletePressed,
                            icon: const Icon(Icons.check),
                            label: const Text('Завершить'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                            ),
                        ),
                ],
            ),
        );
    }
    
    String _formatDate(DateTime date)
    {
        return '${date.day}.${date.month}.${date.year}';
    }
}