// lib/utils/app_version.dart
import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  final String version;
  final int buildNumber;
  
  AppVersion(this.version, this.buildNumber);
  
  factory AppVersion.fromPackageInfo(PackageInfo packageInfo) {
    return AppVersion(
      packageInfo.version,
      int.tryParse(packageInfo.buildNumber) ?? 1,
    );
  }
  
  // Сравниваем версии
  bool isNewerThan(AppVersion other) {
    // Сравниваем версии типа "1.2.3"
    final currentParts = version.split('.').map(int.parse).toList();
    final otherParts = other.version.split('.').map(int.parse).toList();
    
    for (int i = 0; i < Math.max(currentParts.length, otherParts.length); i++) {
      final current = i < currentParts.length ? currentParts[i] : 0;
      final other = i < otherParts.length ? otherParts[i] : 0;
      
      if (current > other) return true;
      if (current < other) return false;
    }
    
    // Если версии одинаковые, сравниваем build number
    //return buildNumber > other.buildNumber;
    return false;
  }
  
  @override
  String toString() => 'v$version (build $buildNumber)';
}

// Добавим Math класс если его нет
class Math {
  static int max(int a, int b) => a > b ? a : b;
}