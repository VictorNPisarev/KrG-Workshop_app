// lib/utils/network_utils.dart
import 'dart:io';
import 'package:flutter/material.dart';

class NetworkUtils
{
    // Проверка подключения к интернету
    static Future<bool> hasInternetConnection() async
    {
        try
        {
            final result = await InternetAddress.lookup('google.com');
            if (result.isNotEmpty && result[0].rawAddress.isNotEmpty)
            {
                print('✅ Есть подключение к интернету');
                return true;
            }
        }
        on SocketException catch (_)
        {
            print('❌ Нет подключения к интернету');
            return false;
        }
        return false;
    }
    
    // Показать диалог об отсутствии интернета
    static void showNoInternetDialog(BuildContext context)
    {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
                title: const Text('Нет подключения к интернету'),
                content: const Text(
                    'Для работы приложения требуется подключение к интернету. '
                    'Проверьте настройки сети и попробуйте снова.',
                ),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Закрыть'),
                    ),
                    TextButton(
                        onPressed: ()
                        {
                            Navigator.pop(context);
                            // Можно добавить повторную проверку
                        },
                        child: const Text('Повторить'),
                    ),
                ],
            ),
        );
    }
}