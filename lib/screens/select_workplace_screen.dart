// lib/screens/select_workplace_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workplace.dart';
import '../providers/auth_provider.dart';

class SelectWorkplaceScreen extends StatelessWidget
{
    const SelectWorkplaceScreen({super.key});
    
    @override
    Widget build(BuildContext context)
    {
        final authProvider = Provider.of<AuthProvider>(context);
        final user = authProvider.currentUser;
        final workplaces = authProvider.availableWorkplaces;
        
        return Scaffold(
            appBar: AppBar(
                title: const Text('Выбор участка'),
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => authProvider.logout(),
                ),
            ),
            body: Column(
                children: [
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    children: [
                                        const Icon(Icons.business, size: 48, color: Colors.blue),
                                        const SizedBox(height: 16),
                                        Text(
                                            user?.name ?? 'Сотрудник',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                            ),
                                        ),
                                        Text(
                                            user?.email ?? '',
                                            style: const TextStyle(color: Colors.grey),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                            'Доступные участки: ${workplaces.length}',
                                            style: const TextStyle(color: Colors.grey),
                                        ),
                                    ],
                                ),
                            ),
                        ),
                    ),
                    
                    Expanded(
                        child: ListView.builder(
                            itemCount: workplaces.length,
                            itemBuilder: (context, index)
                            {
                                final workplace = workplaces[index];
                                return Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                    ),
                                    child: ListTile(
                                        leading: Icon(
                                            workplace.workplaceIcon,//Icons.work,
                                            color: Colors.blue.shade700,
                                        ),
                                        title: Text(
                                            workplace.name,
                                            style: const TextStyle(fontSize: 16),
                                        ),
                                        /*subtitle: workplace.previousWorkplace != null
                                            ? Text('Следующий после: ${workplace.previousWorkplace}')
                                            : const Text('Первый в цепочке'),*/
                                        trailing: const Icon(Icons.arrow_forward),
                                        onTap: () => _selectWorkplace(context, workplace),
                                    ),
                                );
                            },
                        ),
                    ),
                ],
            ),
        );
    }
    
    void _selectWorkplace(BuildContext context, Workplace workplace) async
    {
        final authProvider = context.read<AuthProvider>();
        await authProvider.selectWorkplace(workplace);
    }
}