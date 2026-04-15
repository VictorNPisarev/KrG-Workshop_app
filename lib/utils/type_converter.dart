// lib/utils/type_converter.dart
class TypeConverter
{
	static double toDouble(dynamic value)
	{
		if (value == null) return 0.0;
		if (value is double) return value;
		if (value is int) return value.toDouble();
		if (value is String)
		{
			final normalized = value.replaceFirst(',', '.');
			return double.tryParse(normalized) ?? 0.0;
		}
		return 0.0;
	}

	static int toInt(dynamic value)
	{
		if (value == null) return 0;
		if (value is int) return value;
		if (value is double) return value.toInt();
		if (value is String) return int.tryParse(value) ?? 0;
		return 0;
	}

	static bool toBool(dynamic value)
	{
		if (value == null) return false;
		if (value is bool) return value;
		if (value is String)
		{
			return value.toLowerCase() == 'true' || value == '1' || value == 'да';
		}
		if (value is int) return value == 1;
		return false;
	}
}