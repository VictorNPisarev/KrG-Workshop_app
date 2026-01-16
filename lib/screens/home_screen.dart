import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/orderInProduct.dart';
import '../models/workplace.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_table_widget.dart';
import 'order_detail_screen.dart';

class HomeScreen extends StatefulWidget
{
    const HomeScreen({super.key});
    
    @override
    State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
{
    bool _isInitializing = false;
    String? _error;
    
    @override
    void initState()
    {
        super.initState();
        print('🏠 HomeScreen.initState');
        _initializeData();
    }
    
    void _initializeData()
    {
        if (_isInitializing) return;
        
        setState(() => _isInitializing = true);
        
        // TODO: Получать workplaceId из настроек/авторизации
        const workplaceId = 'kji1GgYVpS4EQLXb11Fkl7';
        
        print('🔄 HomeScreen: инициализация с workplaceId=$workplaceId');
        
        final provider = Provider.of<OrdersProvider>(
            context, 
            listen: false,
        );
        
        provider.initialize(workplaceId).then((_)
        {
            print('✅ HomeScreen: инициализация завершена');
            setState(() => _isInitializing = false);
        }).catchError((e)
        {
            print('❌ HomeScreen: ошибка инициализации - $e');
            setState(()
            {
                _isInitializing = false;
                _error = e.toString();
            });
        });
    }
    
    @override
    Widget build(BuildContext context)
    {
        print('🏠 HomeScreen.build');
        
        final provider = Provider.of<OrdersProvider>(context);
        final workplace = provider.currentWorkplace;
        
        // Показываем индикатор загрузки при первой инициализации
        if (_isInitializing || (provider.isLoading && !provider.isInitialized))
        {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
            );
        }
        
        // Показываем ошибку если есть
        if (_error != null || provider.error != null)
        {
            final errorMessage = _error ?? provider.error;
            return Scaffold(
                appBar: AppBar(title: const Text('Ошибка')),
                body: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            const Icon(Icons.error, color: Colors.red, size: 64),
                            const SizedBox(height: 16),
                            Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                                onPressed: _initializeData,
                                child: const Text('Повторить'),
                            ),
                        ],
                    ),
                ),
            );
        }
        
        // Проверяем, что рабочее место загружено
        if (workplace == null)
        {
            return Scaffold(
                appBar: AppBar(title: const Text('Ошибка')),
                body: const Center(
                    child: Text('Рабочее место не найдено'),
                ),
            );
        }
        
        print('✅ HomeScreen: отрисовываю интерфейс для ${workplace.name}');
        
        // Возвращаем нормальный интерфейс
        return _buildMainInterface(context, provider, workplace);
    }
    
    Widget _buildMainInterface(BuildContext context, OrdersProvider provider, Workplace workplace)
    {
        return DefaultTabController(
            length: 2,
            child: Scaffold(
                appBar: AppBar(
                    title: Text('Участок: ${workplace.name}'),
                    bottom: const TabBar(
                        tabs: [
                            Tab(icon: Icon(Icons.build), text: 'Текущие заказы'),
                            Tab(icon: Icon(Icons.queue), text: 'Ожидают обработки'),
                        ],
                    ),
                    actions: [
                        IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _initializeData,
                            tooltip: 'Обновить',
                        ),
                    ],
                ),
                body: TabBarView(
                    children: [
                        _buildOrdersTab(
                            provider.currentOrders,
                            'Заказов в работе: ${provider.currentOrders.length}',
                            Colors.blue,
                        ),
                        _buildOrdersTab(
                            provider.pendingOrders,
                            'Заказов ожидает: ${provider.pendingOrders.length}',
                            Colors.orange,
                        ),
                    ],
                ),
            ),
        );
    }
    
    Widget _buildOrdersTab(List<OrderInProduct> orders, String summary, Color color)
    {
        // Ваш существующий код вкладки
        return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
                children: [
                    _buildSummaryInfo(summary, color),
                    const SizedBox(height: 16),
                    Expanded(
                        child: OrderTableWidget(
                            orders: orders,
                            onOrderSelected: (order) => _showOrderDetails(order),
                        ),
                    ),
                ],
            ),
        );
    }
    
    Widget _buildSummaryInfo(String text, Color color)
    {
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
                children: [
                    Icon(Icons.info_outline, color: color),
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
                    orderId: order.id,
                    currentWorkplace: workplace,
                ),
            ),
        );
    }
}