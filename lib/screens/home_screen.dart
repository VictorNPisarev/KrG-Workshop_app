import 'package:workshop_app/models/workplace.dart';

import '../models/order.dart';
import '../models/orderInProduct.dart';
import '../widgets/order_card.dart';
import 'package:flutter/material.dart';

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
    }
    
    @override
    Widget build(BuildContext context)
    {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Участок производства'),
                bottom: TabBar(
                    controller: _tabController,
                    tabs: const [
                        Tab(
                            icon: Icon(Icons.build),
                            text: 'Заказы на участке',
                        ),
                        Tab(
                            icon: Icon(Icons.queue),
                            text: 'Заказы в работу',
                        ),
                    ],
                ),
            ),
            body: TabBarView(
                controller: _tabController,
                children: [
                    // TODO: Заменим на реальные виджеты
                    _buildPlaceholderContent('Заказы на участке'),
                    _buildPlaceholderContent('Заказы в работу'),
                ],
            ),
        );
    }
    
    Widget _buildPlaceholderContent(String title)
    {
        // Создаем тестовый заказ
        final testOrder = Order(
            id: '1',
            orderNumber: '2024-001',
            readyDate: DateTime.now().add(const Duration(days: 3)),
            winCount: 5,
            winArea: 10,
            plateCount: 15,
            plateArea: 5,
            claim: false,
            econom: false,
            onlyPayed: false,
        );

        final testWorkplace = Workplace(
            id: '1',
            name: 'Шлифовка',
            isWorkPlace: true,
            nextWorkPlace: null,
            previousWorkPlace: null
        );

        final testOrderInProduct = OrderInProduct(
            id: '1',
            orderId: testOrder.id,
            comment: '',
            glazingBead: '',
            lumber: '',
            twoSidePaint: true,
            workplaceId: testWorkplace.id,
            changeDate: DateTime.now(),
            order: testOrder,
            status: OrderStatus.inProgress,
        );
        
        return ListView(
            padding: const EdgeInsets.all(8),
            children: [
                OrderCard(
                    orderInProduct: testOrderInProduct,
                    showCompleteButton: title == 'Заказы на участке',
                    showStartButton: title == 'Заказы в работу',
                    onCompletePressed: ()
                    {
                        print('Завершить заказ ${testOrder.orderNumber}');
                    },
                    onStartPressed: ()
                    {
                        print('Взять в работу заказ ${testOrder.orderNumber}');
                    },
                ),
            ],
        );
    }

    @override
    void dispose()
    {
        _tabController.dispose();
        super.dispose();
    }
}