// lib/config/app_config.dart
class AppConfig 
{
	final String name;
	final String apiUrl;
	final bool isProduction;

	const AppConfig({
		required this.name,
		required this.apiUrl,
		required this.isProduction,
	});

	// Продакшен конфигурация (GAS)
	static const AppConfig production = AppConfig(
		name: 'GAS (Google Apps Script)',
		apiUrl: 'https://script.google.com/macros/s/AKfycbzoDyvGU4ZHKg4oy1rGmxvxLTfnMATV21eYUzTFsj4pTxz3ii3sqw-i6fk5vElvrqBR-w/exec',
		isProduction: true,
	);

	// Тестовая конфигурация (Node.js)
	static const AppConfig development = AppConfig(
		name: 'Node.js (Local)',
		apiUrl: 'http://192.168.0.179:3000/api',
		isProduction: false,
	);

	// Список всех доступных конфигураций
	static const List<AppConfig> all = [production, development];
}