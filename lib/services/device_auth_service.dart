// lib/services/device_auth_service.dart
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DeviceAuthService
{
    static const platform = MethodChannel('com.yourapp/device_email');
    
    // Получение email через Google Sign-In (для Android)
    static Future<String?> getEmailFromGoogle() async
    {
        try
        {
            final GoogleSignIn googleSignIn = GoogleSignIn(
                scopes: ['email', 'profile'],
            );
            
            final account = await googleSignIn.signInSilently();
            if (account != null)
            {
                return account.email;
            }
            
            final signedInAccount = await googleSignIn.signIn();
            return signedInAccount?.email;
        }
        catch (e)
        {
            print('❌ Ошибка Google Sign-In: $e');
            return null;
        }
    }
    
    // Получение email через нативный код (Android/iOS)
    static Future<String?> getDeviceEmail() async
    {
        try
        {
            final email = await platform.invokeMethod<String>('getDeviceEmail');
            return email;
        }
        on PlatformException catch (e)
        {
            print('❌ Ошибка платформы: ${e.message}');
            return null;
        }
        catch (e)
        {
            print('❌ Ошибка получения email: $e');
            return null;
        }
    }
    
    // Проверка, есть ли сохраненный email на устройстве
    static Future<bool> hasDeviceEmail() async
    {
        try
        {
            final hasEmail = await platform.invokeMethod<bool>('hasDeviceEmail') ?? false;
            return hasEmail;
        }
        catch (e)
        {
            return false;
        }
    }
}