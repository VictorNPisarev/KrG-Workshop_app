import 'package:flutter/material.dart';
import 'order_table_widget.dart';
import '../models/order_in_product.dart';

class PaginatedOrderTable extends StatefulWidget {
  final List<OrderInProduct> orders;
  final Function(OrderInProduct) onOrderSelected;
  final bool isCurrentTab;
  final String tabKey; // Уникальный ключ для сброса состояния

  const PaginatedOrderTable({
    super.key,
    required this.orders,
    required this.onOrderSelected,
    required this.tabKey,
    this.isCurrentTab = true,
  });

  @override
  State<PaginatedOrderTable> createState() => _PaginatedOrderTableState();
}

class _PaginatedOrderTableState extends State<PaginatedOrderTable>
    with AutomaticKeepAliveClientMixin {
  final int _pageSize = 20;
  int _currentPage = 0;
  String? _previousTabKey;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _previousTabKey = widget.tabKey;
  }

  @override
  void didUpdateWidget(PaginatedOrderTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Сбрасываем страницу если:
    // 1. Изменился ключ вкладки
    // 2. Изменилось количество заказов
    // 3. Изменился первый заказ в списке (простая проверка на новые данные)
    if (widget.tabKey != oldWidget.tabKey ||
        widget.orders.length != oldWidget.orders.length ||
        (widget.orders.isNotEmpty &&
            oldWidget.orders.isNotEmpty &&
            widget.orders.first.id != oldWidget.orders.first.id)) {
      _currentPage = 0;
      _previousTabKey = widget.tabKey;
    }
  }

  List<OrderInProduct> get _currentPageOrders {
    if (widget.orders.isEmpty) return [];

    final start = _currentPage * _pageSize;
    if (start >= widget.orders.length) {
      return [];
    }

    final end = start + _pageSize;
    return widget.orders.sublist(
      start,
      end < widget.orders.length ? end : widget.orders.length,
    );
  }

  int get _totalPages {
    if (widget.orders.isEmpty) return 1;
    return (widget.orders.length / _pageSize).ceil();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Column(
      children: [
        // Информация о странице
        if (widget.orders.length > _pageSize)
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Страница ${_currentPage + 1} из $_totalPages',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Заказы ${_currentPage * _pageSize + 1}-${(_currentPage * _pageSize + _currentPageOrders.length)} из ${widget.orders.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

        // Основная таблица
        Expanded(
          child: OrderTableWidget(
            orders: _currentPageOrders,
            onOrderSelected: widget.onOrderSelected,
            isCurrentTab: widget.isCurrentTab,
          ),
        ),

        // Пагинация (только если больше одной страницы)
        if (_totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Кнопка "назад"
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                  color: _currentPage > 0 ? Colors.blue : Colors.grey,
                ),

                // Номера страниц
                Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_totalPages, (index) {
                        return GestureDetector(
                          onTap: () => setState(() => _currentPage = index),
                          child: Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.blue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _currentPage == index
                                    ? Colors.blue
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: _currentPage == index
                                    ? Colors.white
                                    : Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                // Кнопка "вперед"
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  onPressed: _currentPage < _totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                  color: _currentPage < _totalPages - 1 ? Colors.blue : Colors.grey,
                ),
              ],
            ),
          ),
      ],
    );
  }
}