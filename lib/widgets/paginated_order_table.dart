import 'package:flutter/material.dart';
import 'order_table_widget.dart';
import '../models/order_in_product.dart';

class PaginatedOrderTable extends StatefulWidget {
  final List<OrderInProduct> orders;
  final Function(OrderInProduct) onOrderSelected;
  final bool isCurrentTab;
  
  const PaginatedOrderTable({
    super.key,
    required this.orders,
    required this.onOrderSelected,
    this.isCurrentTab = true,
  });
  
  @override
  State<PaginatedOrderTable> createState() => _PaginatedOrderTableState();
}

class _PaginatedOrderTableState extends State<PaginatedOrderTable> {
  final int _pageSize = 20; // Заказов на страницу
  int _currentPage = 0;
  
  List<OrderInProduct> get _currentPageOrders {
    if (widget.orders.isEmpty) return [];
    
    final start = _currentPage * _pageSize;
    // Проверяем, чтобы не выйти за пределы списка
    if (start >= widget.orders.length) {
      _currentPage = 0; // Возвращаем на первую страницу
      return _getPage(0);
    }
    
    return _getPage(_currentPage);
  }
  
  List<OrderInProduct> _getPage(int page) {
    final start = page * _pageSize;
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
    return Column(
      children: [
        // Показываем информацию о странице, если заказов много
        if (widget.orders.length > _pageSize)
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Заказы ${_currentPage * _pageSize + 1}-${(_currentPage * _pageSize + _currentPageOrders.length)} из ${widget.orders.length}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        
        // Основная таблица с заказами текущей страницы
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
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Кнопка "назад"
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _currentPage > 0 
                      ? () => setState(() => _currentPage--)
                      : null,
                  color: _currentPage > 0 ? Colors.blue : Colors.grey,
                ),
                
                // Индикатор страниц
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    children: List.generate(_totalPages, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => _currentPage = index),
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _currentPage == index 
                                ? Colors.blue 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: _currentPage == index 
                                  ? Colors.white 
                                  : Colors.blue,
                              fontWeight: _currentPage == index 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                
                // Кнопка "вперед"
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
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