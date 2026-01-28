import 'package:flutter/material.dart';
import '../models/order_in_product.dart';

class OrderTableWidget extends StatelessWidget {
  final List<OrderInProduct> orders;
  final Function(OrderInProduct) onOrderSelected;
  final bool isCurrentTab;

  const OrderTableWidget({
    super.key,
    required this.orders,
    required this.onOrderSelected,
    this.isCurrentTab = true,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columnSpacing: 20,
          horizontalMargin: 12,
          columns: _buildTableColumns(),
          rows: _buildTableRows(),
        ),
      ),
    );
  }

  List<DataColumn> _buildTableColumns() {
    return const [
      DataColumn(
        label: Text(
          '№ Заказа',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn(
        label: Text(
          'Дата готовности',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn(
        label: Text(
          'Кол-во окон',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn(
        label: Text(
          'Статус',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ];
  }

  List<DataRow> _buildTableRows() {
    return orders.map((order) {
      return DataRow(
        cells: _buildRowCells(order),
        onSelectChanged: (_) => onOrderSelected(order),
      );
    }).toList();
  }

  List<DataCell> _buildRowCells(OrderInProduct order) {
    // Определяем символы для претензий и щитовых изделий
    String prefix = '';
    if (order.claim) prefix += '⚠ ';
    if (order.winCount == 0 && order.plateCount > 0) prefix += '≡ ';

    return [
      DataCell(
        Text(
          '$prefix${order.orderNumber}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: order.claim ? Colors.red : null,
          ),
        ),
      ),
      DataCell(Text(_formatDate(order.readyDate))),
      DataCell(Text('${order.winCount} шт')),
      DataCell(
        Chip(
          label: Text(
            order.status.displayName,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          backgroundColor: _getStatusColor(order.status),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ),
        ),
      ),
    ];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCurrentTab ? Icons.work_outline : Icons.hourglass_empty,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isCurrentTab ? 'Нет заказов в работе' : 'Нет ожидающих заказов',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
    }
  }
}