// lib/widgets/order_table_widget.dart
import 'package:flutter/material.dart';
import '../models/orderInProduct.dart';

class OrderTableWidget extends StatelessWidget
{
    final List<OrderInProduct> orders;
    final Function(OrderInProduct) onOrderSelected;
    
    const OrderTableWidget({
        super.key,
        required this.orders,
        required this.onOrderSelected,
    });
    
    @override
    Widget build(BuildContext context)
    {
        if (orders.isEmpty)
        {
            return const Center(
                child: Text('Нет заказов для отображения'),
            );
        }
        
        return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                    columnSpacing: 20,
                    horizontalMargin: 12,
                    columns: _buildTableColumns(),
                    rows: _buildTableRows(context),
                ),
            ),
        );
    }
    
    List<DataColumn> _buildTableColumns()
    {
        return [
            const DataColumn(
                label: Text(
                    '№ Заказа',
                    style: TextStyle(fontWeight: FontWeight.bold),
                ),
            ),
            const DataColumn(
                label: Text(
                    'Дата готовности',
                    style: TextStyle(fontWeight: FontWeight.bold),
                ),
            ),
            const DataColumn(
                label: Text(
                    'Кол-во окон',
                    style: TextStyle(fontWeight: FontWeight.bold),
                ),
            ),
            const DataColumn(
                label: Text(
                    'Статус',
                    style: TextStyle(fontWeight: FontWeight.bold),
                ),
            ),
        ];
    }
    
    List<DataRow> _buildTableRows(BuildContext context)
    {
        return orders.map((order)
        {
            return DataRow(
                cells: _buildRowCells(order, context),
                onSelectChanged: (_) => onOrderSelected(order),
            );
        }).toList();
    }
    
    List<DataCell> _buildRowCells(OrderInProduct orderInProduct, BuildContext context)
    {
        final orderData = orderInProduct.order;
        
        return [
            DataCell(
                Text((orderData != null ? orderData.winCount == 0 && orderData.plateCount > 0 ? '≡' : 
                                          orderData.claim ? '' : ''
                                        : '') + 
                    (orderData?.orderNumber ?? 'Нет номера'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                ),
            ),
            DataCell(Text(_formatDate(orderData?.readyDate ?? DateTime.now()))),
            DataCell(Text('${orderData?.winCount} шт')),
            DataCell(
                Chip(
                    label: Text(
                        orderInProduct.status.displayName,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                        ),
                    ),
                    backgroundColor: _getStatusColor(orderInProduct.status),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                    ),
                ),
            ),
        ];
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