import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/orderInProduct.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_table_widget.dart';
import 'order_detail_screen.dart';

class HomeScreen extends StatefulWidget
{
    const HomeScreen({super.key});
    
    @override
    State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin
{
    late TabController _tabController;
    
    @override
    void initState()
    {
        super.initState();
        _tabController = TabController(length: 2, vsync: this);
        
        // Инициализируем данные после первой отрисовки
        WidgetsBinding.instance.addPostFrameCallback((_)
        {
            _initializeData();
        });
    }
    
    void _initializeData()
    {
        final provider = Provider.of<OrdersProvider>(context, listen: false);
        
        // TODO: В будущем здесь будет ID из авторизации

        provider.initialize('vJ8sXoQ40F4SIhEqcMha7c');
    }
    
    @override
    Widget build(BuildContext context)
    {
        final provider = Provider.of<OrdersProvider>(context);
        
        final workplace = provider.currentWorkplace;
        
        if (provider.isLoading && provider.currentWorkplace == null)
        {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
            );
        }

        if (provider.error != null && provider.currentOrders.isEmpty && provider.pendingOrders.isEmpty)
        {
            return Scaffold(
                appBar: AppBar(title: const Text('Ошибка')),
                body: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                    provider.error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.grey),
                                ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                                onPressed: () => provider.refreshOrders(),
                                child: const Text('Повторить'),
                            ),
                        ],
                    ),
                ),
            );
        }

        if (workplace == null)
        {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
            );
        }
        
        return Scaffold(
            appBar: AppBar(
                title: Text('Участок: ${workplace.name}'),
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
                actions: [
                    IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => provider.refreshOrders(),
                        tooltip: 'Обновить',
                    ),
                ],
            ),
            body: TabBarView(
                controller: _tabController,
                children: [
                    // Вкладка текущих заказов
                    _buildOrdersTab(
                        provider.currentOrders,
                        'Заказов в работе: ${provider.currentOrders.length}',
                        Colors.blue,
                    ),
                    
                    // Вкладка ожидающих заказов
                    _buildOrdersTab(
                        provider.pendingOrders,
                        'Заказов ожидает: ${provider.pendingOrders.length}',
                        Colors.orange,
                    ),
                ],
            ),
        );
    }
    
    Widget _buildOrdersTab(List<OrderInProduct> orders, String summary, Color color)
    {
        return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
                children: [
                    _buildSummaryInfo(summary, color),
                    const SizedBox(height: 16),
                    Expanded(
                        child: OrderTableWidget(
                            orders: orders,
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
    final provider = Provider.of<OrdersProvider>(context, listen: false);
    final workplace = provider.currentWorkplace;
    
    if (workplace == null) return;
    
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => OrderDetailScreen(
                orderId: order.id, // Передаем только ID
                currentWorkplace: workplace,
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