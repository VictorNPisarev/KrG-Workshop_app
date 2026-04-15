// lib/services/config_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ConfigService
{
	static const String _keySelectedConfig = 'selected_config_index';
	
	// Текущий выбранный сервер
	static AppConfig? _currentConfig;
	
	static Future<AppConfig> getCurrentConfig() async
	{
		if (_currentConfig != null) return _currentConfig!;
		
		final prefs = await SharedPreferences.getInstance();
		final savedIndex = prefs.getInt(_keySelectedConfig) ?? 0;
		
		// Защита от выхода за пределы списка
		final index = savedIndex.clamp(0, AppConfig.all.length - 1);
		_currentConfig = AppConfig.all[index];
		
		return _currentConfig!;
	}
	
	static Future<void> setCurrentConfig(int index) async
	{
		if (index < 0 || index >= AppConfig.all.length) return;
		
		final prefs = await SharedPreferences.getInstance();
		await prefs.setInt(_keySelectedConfig, index);
		_currentConfig = AppConfig.all[index];
	}
	
	static Future<String> getApiUrl() async
	{
		final config = await getCurrentConfig();
		return config.apiUrl;
	}
	
	static Future<String> getConfigName() async
	{
		final config = await getCurrentConfig();
		return config.name;
	}
	
	static Future<bool> isDevelopment() async
	{
		final config = await getCurrentConfig();
		return !config.isProduction;
	}
}