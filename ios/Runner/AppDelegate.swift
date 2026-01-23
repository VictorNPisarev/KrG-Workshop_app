// ios/Runner/AppDelegate.swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "RedHill.workshop_app/device_email",
                                           binaryMessenger: controller.binaryMessenger)
        
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            if call.method == "getDeviceEmail" {
                let email = self.getDeviceEmail()
                result(email)
            } else if call.method == "hasDeviceEmail" {
                let hasEmail = self.getDeviceEmail() != nil
                result(hasEmail)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func getDeviceEmail() -> String? {
        // Для iOS нужно использовать Keychain или Apple Sign-In
        // Это упрощенный пример
        return UserDefaults.standard.string(forKey: "device_email")
    }
}