// screens/order_search_screen.dart
import 'package:flutter/material.dart';
import 'package:workshop_app/models/order_trace.dart';
import 'package:workshop_app/services/data_service.dart';

import '../models/workplace_status.dart';

class OrderSearchScreen extends StatefulWidget 
{
	const OrderSearchScreen({super.key});

	@override
	State<OrderSearchScreen> createState() => _OrderSearchScreenState();
}

class _OrderSearchScreenState extends State<OrderSearchScreen> 
{
	final TextEditingController _searchController = TextEditingController();
	final FocusNode _focusNode = FocusNode();
	List<OrderTrace> _searchResults = [];
	bool _isLoading = false;
	String? _error;

	@override
	void dispose() 
	{
		_searchController.dispose();
		_focusNode.dispose();
		super.dispose();
	}

	Future<void> _searchOrder() async 
	{
		final orderNumber = _searchController.text.trim();
		if (orderNumber.isEmpty) 
		{
			setState(() => _error = 'Введите номер заказа');
			return;
		}

		// Скрываем клавиатуру
		_focusNode.unfocus();

		setState(() 
		{
			_isLoading = true;
			_error = null;
			_searchResults.clear();
		});

		try 
		{
			final results = await DataService.getOrderTrace(orderNumber);
			setState(() 
			{
				_searchResults = results;
				if (results.isEmpty) 
				{
					_error = 'Заказ "$orderNumber" не найден';
				}
			});
		} 
		catch (e) 
		{
			setState(() => _error = 'Ошибка поиска: $e');
		} 
		finally 
		{
			setState(() => _isLoading = false);
		}
	}

	@override
	Widget build(BuildContext context) 
	{
		return Scaffold(
			appBar: AppBar(
				title: const Text('Поиск заказа'),
				centerTitle: true,
			),
			body: SafeArea(
				child: Center(
					child: ConstrainedBox(
						constraints: const BoxConstraints(
							maxWidth: 600, // Максимальная ширина контента
						),
						child: Padding(
							padding: const EdgeInsets.all(16),
							child: Column(
								children: [
									// Поле поиска с кнопкой внизу
									TextField(
										controller: _searchController,
										focusNode: _focusNode,
										decoration: InputDecoration(
											hintText: 'Введите номер заказа',
											border: OutlineInputBorder(
												borderRadius: BorderRadius.circular(12),
											),
											prefixIcon: const Icon(Icons.search),
											suffixIcon: _searchController.text.isNotEmpty
													? IconButton(
															icon: const Icon(Icons.clear),
															onPressed: () 
															{
																_searchController.clear();
																setState(() {
																	_searchResults.clear();
																	_error = null;
																});
															},
														)
													: null,
										),
										textInputAction: TextInputAction.done,
										onSubmitted: (_) => _searchOrder(),
									),
									
									const SizedBox(height: 12),
									
									// Кнопка "Найти" под полем
									SizedBox(
										width: double.infinity,
										child: ElevatedButton(
											onPressed: _isLoading ? null : _searchOrder,
											style: ElevatedButton.styleFrom(
												padding: const EdgeInsets.symmetric(vertical: 14),
												shape: RoundedRectangleBorder(
													borderRadius: BorderRadius.circular(12),
												),
											),
											child: _isLoading
													? const SizedBox(
															height: 20,
															width: 20,
															child: CircularProgressIndicator(strokeWidth: 2),
														)
													: const Text(
															'Найти',
															style: TextStyle(fontSize: 16),
														),
										),
									),
									
									const SizedBox(height: 24),
									
									// Состояния
									Expanded(
										child: _buildContent(),
									),
								],
							),
						),
					),
				),
			),
		);
	}

	Widget _buildContent() 
	{
		if (_isLoading) 
		{
			return const Center(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						CircularProgressIndicator(),
						SizedBox(height: 16),
						Text('Поиск заказа...'),
					],
				),
			);
		}

		if (_error != null) 
		{
			return Center(
				child: Container(
					padding: const EdgeInsets.all(16),
					decoration: BoxDecoration(
						color: Colors.red.shade50,
						borderRadius: BorderRadius.circular(12),
						border: Border.all(color: Colors.red.shade200),
					),
					child: Row(
						mainAxisSize: MainAxisSize.min,
						children: [
							const Icon(Icons.error, color: Colors.red),
							const SizedBox(width: 12),
							Expanded(child: Text(_error!)),
						],
					),
				),
			);
		}

		if (_searchResults.isEmpty) 
		{
			return Center(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(
							Icons.search_off,
							size: 64,
							color: Colors.grey.shade400,
						),
						const SizedBox(height: 16),
						Text(
							'Введите номер заказа для поиска',
							style: TextStyle(color: Colors.grey.shade600),
						),
					],
				),
			);
		}

		return ListView.builder(
			itemCount: _searchResults.length,
			itemBuilder: (context, index) 
			{
				final trace = _searchResults[index];
				return _buildOrderTraceCard(trace);
			},
		);
	}

	Widget _buildOrderTraceCard(OrderTrace trace) 
	{
		return Card(
			margin: const EdgeInsets.symmetric(vertical: 8),
			shape: RoundedRectangleBorder(
				borderRadius: BorderRadius.circular(12),
			),
			child: ExpansionTile(
				title: Row(
					children: [
						Expanded(
							child: Text(
								'Заказ: ${trace.orderNumber}',
								style: const TextStyle(fontWeight: FontWeight.bold),
							),
						),
						Container(
							padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
							decoration: BoxDecoration(
								color: Colors.grey.shade200,
								borderRadius: BorderRadius.circular(16),
							),
							/*child: Text(
								_formatDate(trace.readyDate),
								style: const TextStyle(fontSize: 12),
							),*/
						),
					],
				),
				subtitle: Padding(
					padding: const EdgeInsets.only(top: 4),
					child: Text(
						'Готовность: ${_formatDate(trace.readyDate)}',
						style: TextStyle(fontSize: 14, color: const Color.fromARGB(255, 49, 49, 49)),
					),
				),
				children: 
				[
					Padding(
						padding: const EdgeInsets.all(16),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								const Text(
									'Цепочка участков:',
									style: TextStyle(fontWeight: FontWeight.bold),
								),
								const SizedBox(height: 12),
								...trace.workplaces.map((wp) => _buildWorkplaceRow(wp)),
							],
						),
					),
				],
			),
		);
	}

	Widget _buildWorkplaceRow(WorkplaceStatus wp) 
	{
		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 8),
			child: Row(
				children: 
				[
					Container(
						width: 36,
						child: Icon(
							wp.statusIcon,
							color: wp.statusColor,
							size: 22,
						),
					),
					Expanded(
						child: Text(
							wp.name,
							style: const TextStyle(fontSize: 15),
						),
					),
					Container(
						padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
						decoration: BoxDecoration(
							color: wp.statusColor.withValues(alpha: 0.1),
							borderRadius: BorderRadius.circular(20),
						),
						child: Text(
							wp.status.displayName,
							style: TextStyle(
								color: wp.statusColor,
								fontWeight: FontWeight.w500,
								fontSize: 11,
							),
						),
					),
				],
			),
		);
	}


	String _formatDate(DateTime date) 
	{
		return '${date.day.toString().padLeft(2, '0')}.'
				'${date.month.toString().padLeft(2, '0')}.'
				'${date.year}';
	}
}