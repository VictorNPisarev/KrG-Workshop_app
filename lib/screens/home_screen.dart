import 'package:flutter/material.dart';
import 'package:workshop_app/models/orderInProduct.dart';
import 'package:workshop_app/models/workplace.dart';
import '../services/data_service.dart';
import '../widgets/order_table_widget.dart';
import 'order_detail_screen.dart';

class HomeScreen extends StatefulWidget
{
    final String currentWorkplaceId;
    
    const HomeScreen({
        super.key,
        required this.currentWorkplaceId,
    });
    
    @override
    State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin
{
    late TabController _tabController;
    late List<OrderInProduct> _currentOrders;
    late List<OrderInProduct> _pendingOrders;
    late Workplace _currentWorkplace;
    
    @override
    void initState()
    {
        super.initState();
        _tabController = TabController(length: 2, vsync: this);
        _loadData();
    }
    
    void _loadData()
    {
        // Получаем данные текущего участка
        final workplace = DataService.getWorkplaceById(widget.currentWorkplaceId);
        if (workplace == null)
        {
            throw Exception('Участок с ID ${widget.currentWorkplaceId} не найден');
        }
        
        _currentWorkplace = workplace;
        
        // Загружаем заказы
        setState(()
        {
            _currentOrders = DataService.getCurrentOrders(widget.currentWorkplaceId);
            _pendingOrders = DataService.getPendingOrders(widget.currentWorkplaceId);
        });
    }
    
    @override
    Widget build(BuildContext context)
    {
        return Scaffold(
            appBar: AppBar(
                title: Text('Участок: ${_currentWorkplace.name}'),
                bottom: TabBar(
                    controller: _tabController,
                    tabs: const [
                        Tab(
                            icon: Icon(Icons.build),
                            text: 'Текущие заказы',
                        ),
                        Tab(
                            icon: Icon(Icons.queue),
                            text: 'Ожидают обработки',
                        ),
                    ],
                ),
            ),
            body: TabBarView(
                controller: _tabController,
                children: [
                    // Вкладка текущих заказов
                    _buildCurrentOrdersTab(),
                    
                    // Вкладка ожидающих заказов
                    _buildPendingOrdersTab(),
                ],
            ),
        );
    }
    
    Widget _buildCurrentOrdersTab()
    {
        return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
                children: [
                    _buildSummaryInfo(
                        'Заказов в работе: ${_currentOrders.length}',
                        Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                        child: OrderTableWidget(
                            orders: _currentOrders,
                            onOrderSelected: _showOrderDetails,
                        ),
                    ),
                ],
            ),
        );
    }
    
    Widget _buildPendingOrdersTab()
    {
        return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
                children: [
                    _buildSummaryInfo(
                        'Заказов ожидает: ${_pendingOrders.length}',
                        Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                        child: OrderTableWidget(
                            orders: _pendingOrders,
                            onOrderSelected: _showOrderDetails,
                        ),
                    ),
                ],
            ),
        );
    }
    
    Widget _buildSummaryInfo(String text, Color color)
    {
        return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
            ),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
                children: [
                    Icon(
                        Icons.info_outline,
                        color: color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                        text,
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: color,
                        ),
                    ),
                ],
            ),
        );
    }
    
    void _showOrderDetails(OrderInProduct order)
    {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => OrderDetailScreen(
                    orderInProduct: order,
                    currentWorkplace: _currentWorkplace,
                ),
            ),
        );
    }
    
    @override
    void dispose()
    {
        _tabController.dispose();
        super.dispose();
    }
}