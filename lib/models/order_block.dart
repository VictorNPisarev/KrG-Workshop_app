// lib/models/order_block.dart
class OrderBlock
{
	final String id;
	final String reason;
	final DateTime blockedAt;
	final String userId;

	OrderBlock({
		required this.id,
		required this.reason,
		required this.blockedAt,
		required this.userId,
	});

	factory OrderBlock.fromJson(Map<String, dynamic> json)
	{
		return OrderBlock(
			id: json['id']?.toString() ?? '',
			reason: json['reason']?.toString() ?? '',
			blockedAt:
					DateTime.tryParse(json['blockedAt']?.toString() ?? '') ??
					DateTime.now(),
			userId: json['userId']?.toString() ?? '',
		);
	}
}
