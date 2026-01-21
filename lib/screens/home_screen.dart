// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_in_product.dart';
import '../models/workplace.dart';
import '../providers/auth_provider.dart';
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
        
        WidgetsBinding.instance.addPostFrameCallback((_)
        {
            _initializeHomeScreen();
        });
    }
    
    void _initializeHomeScreen()
    {
        final authProvider = context.read<AuthProvider>();
        final ordersProvider = context.read<OrdersProvider>();
        
        final workplace = authProvider.currentWorkplace;
        if (workplace != null)
        {
            ordersProvider.initialize(workplace.id);
        }
    }
    
    @override
    Widget build(BuildContext context)
    {
        final authProvider = Provider.of<AuthProvider>(context);
        final ordersProvider = Provider.of<OrdersProvider>(context);
        final workplace = authProvider.currentWorkplace;
        
        if (workplace == null)
        {
            return const Scaffold(
                body: Center(
                    child: Text('Рабочее место не выбрано'),
                ),
            );
        }
        
        if (ordersProvider.isLoading && !ordersProvider.isInitialized)
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
                        onPressed: () => _refreshData(),
                        tooltip: 'Обновить',
                    ),
                ],
            ),
            drawer: _buildDrawer(),
            body: TabBarView(
                controller: _tabController,
                children: [
                    _buildOrdersTab(
                        ordersProvider.currentOrders,
                        'Заказов в работе: ${ordersProvider.currentOrders.length}',
                        Colors.blue,
                    ),
                    _buildOrdersTab(
                        ordersProvider.pendingOrders,
                        'Заказов ожидает: ${ordersProvider.pendingOrders.length}',
                        Colors.orange,
                    ),
                ],
            ),
        );
    }
    
    Drawer _buildDrawer()
    {
        final authProvider = Provider.of<AuthProvider>(context);
        final user = authProvider.currentUser;
        final workplaces = authProvider.availableWorkplaces;
        final currentWorkplace = authProvider.currentWorkplace;
        
        return Drawer(
            child: ListView(
                children: [
                    UserAccountsDrawerHeader(
                        accountName: Text(user?.name ?? 'Сотрудник'),
                        accountEmail: Text(user?.email ?? ''),
                        currentAccountPicture: const CircleAvatar(
                            child: Icon(Icons.person),
                        ),
                    ),
                    
                    // Текущий участок
                    ListTile(
                        leading: const Icon(Icons.work),
                        title: const Text('Текущий участок'),
                        subtitle: Text(currentWorkplace?.name ?? 'Не выбран'),
                    ),
                    
                    const Divider(),
                    
                    // Переключение участков
                    if (workplaces.length > 1) ...[
                        const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                                'Переключить участок:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                ),
                            ),
                        ),
                        
                        ...workplaces.map((workplace)
                        {
                            return ListTile(
                                leading: Icon(
                                    Icons.switch_account,
                                    color: workplace.id == currentWorkplace?.id
                                        ? Colors.blue
                                        : Colors.grey,
                                ),
                                title: Text(workplace.name),
                                trailing: workplace.id == currentWorkplace?.id
                                    ? const Icon(Icons.check, color: Colors.blue)
                                    : null,
                                onTap: () => _switchWorkplace(workplace),
                            );
                        }).toList(),
                        
                        const Divider(),
                    ],
                    
                    // Профиль
                    ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Профиль'),
                        onTap: () => _showProfile(context),
                    ),
                    
                    // Настройки
                    ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Настройки'),
                        onTap: () => _showSettings(context),
                    ),
                    
                    const Divider(),
                    
                    // Выход с подтверждением
                    ListTile(
                        leading: const Icon(Icons.exit_to_app, color: Colors.red),
                        title: const Text('Выйти', style: TextStyle(color: Colors.red)),
                        onTap: () => _confirmLogout(context),
                    ),
                ],
            ),
        );
    }
    
    void _confirmLogout(BuildContext context)
    {
        showDialog(
            context: context,
            builder: (BuildContext context)
            {
                return AlertDialog(
                    title: const Text('Выход'),
                    content: const Text('Вы уверены, что хотите выйти?'),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Отмена'),
                        ),
                        TextButton(
                            onPressed: ()
                            {
                                Navigator.pop(context); // Закрыть диалог
                                _logout(context); // Выполнить выход
                            },
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                            ),
                            child: const Text('Выйти'),
                        ),
                    ],
                );
            },
        );
    }
    
    void _logout(BuildContext context) async
    {
        try
        {
            print('🚪 Выход из системы...');
            
            // 1. Получаем провайдеры
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
            
            // 2. Выполняем выход
            await authProvider.logout();
            ordersProvider.clearData(); // Очищаем данные заказов
            
            // 3. Закрываем Drawer если открыт
            if (Scaffold.of(context).isDrawerOpen)
            {
                Navigator.pop(context); // Закрываем Drawer
            }
            
            print('✅ Выход выполнен успешно');
        }
        catch (e)
        {
            print('❌ Ошибка при выходе: $e');
            
            // Показываем ошибку пользователю
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Ошибка при выходе: $e'),
                    backgroundColor: Colors.red,
                ),
            );
        }
    }
    
    void _showProfile(BuildContext context)
    {
        // TODO: Реализовать экран профиля
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Профиль (в разработке)')),
        );
    }
    
    void _showSettings(BuildContext context)
    {
        // TODO: Реализовать экран настроек
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Настройки (в разработке)')),
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
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final workplace = authProvider.currentWorkplace;
        
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
    
    void _refreshData()
    {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
        
        final workplace = authProvider.currentWorkplace;
        if (workplace != null)
        {
            ordersProvider.initialize(workplace.id);
        }
    }
    
    void _switchWorkplace(Workplace workplace) async
    {
        final authProvider = context.read<AuthProvider>();
        final ordersProvider = context.read<OrdersProvider>();
        
        await authProvider.selectWorkplace(workplace);
        await ordersProvider.initialize(workplace.id);
        
        // Закрываем Drawer
        Navigator.pop(context);
    }
    
    @override
    void dispose()
    {
        _tabController.dispose();
        super.dispose();
    }
}