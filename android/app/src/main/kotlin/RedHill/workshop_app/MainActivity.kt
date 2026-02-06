
// android/app/src/main/kotlin/com/yourapp/MainActivity.kt
package RedHill.workshop_app

import android.accounts.Account
import android.accounts.AccountManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "RedHill.workshop_app/device_email"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            
            when (call.method) {
                "getDeviceEmail" -> {
                    val email = getDeviceEmail()
                    result.success(email)
                }
                "hasDeviceEmail" -> {
                    val hasEmail = hasDeviceEmail()
                    result.success(hasEmail)
                }
                "getUriForFile" -> {
                    val filePath = call.arguments as String
                    val uri = getUriForFile(filePath)
                    result.success(uri)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun getDeviceEmail(): String? {
        try {
            val accountManager = getSystemService(Context.ACCOUNT_SERVICE) as AccountManager
            val accounts = accountManager.accounts
            
            // Ищем Google аккаунт
            for (account in accounts) {
                if (account.type.contains("google", ignoreCase = true)) {
                    return account.name
                }
            }
            
            // Если Google не найден, берем первый доступный
            return accounts.firstOrNull()?.name
        } catch (e: Exception) {
            return null
        }
    }
    
    private fun hasDeviceEmail(): Boolean {
        return getDeviceEmail() != null
    }

    private fun getUriForFile(filePath: String): String {
    val file = File(filePath)
    return androidx.core.content.FileProvider.getUriForFile(
        this,
        "${BuildConfig.APPLICATION_ID}.fileprovider",
        file
    ).toString()
    }
}