// lib/models/order_attribute.dart
class OrderAttribute
{
	final String key;
	final String icon;
	final String displayText;
	final dynamic value;

	OrderAttribute({
		required this.key,
		required this.icon,
		required this.displayText,
		required this.value,
	});

	factory OrderAttribute.fromJson(Map<String, dynamic> json)
	{
		return OrderAttribute(
			key: json['key']?.toString() ?? '',
			icon: json['icon']?.toString() ?? '',
			displayText: json['displayText']?.toString() ?? '',
			value: json['value'],
		);
	}
}
