//
//  AppDelegate.swift
//  SwiftPayKit
//
//  Created by Jivan on 2022/5/23.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        var urlSchemeDict: [String: Any] = [:]
        if let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] {
            for urlType in urlTypes {
                if let schemes = urlType["CFBundleURLSchemes"] as? [String], let scheme = schemes.first {
                    // 这里以URL Scheme作为键，可以添加其他相关信息作为值
                    if let name = urlType["CFBundleURLName"] as? String {
                        urlSchemeDict[name] = scheme
                    }
                }
            }
        }

        // 打印URL Scheme字典
        print("URL Scheme字典: \(urlSchemeDict)")
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }
}

