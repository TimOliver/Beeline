//
//  AppDelegate.swift
//  BeelineTest
//
//  Created by Tim Oliver on 13/7/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions
                        launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Register our global router
        Router.registerDefaultClass(AppRouter.self)

        // Create the navigation controller
        let navigationController = UINavigationController(rootViewController: ViewController(number: 1))

        // Create and show the window
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        return true
    }
}

