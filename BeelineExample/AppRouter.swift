//
//  AppRouter.swift
//  BeelineTest
//
//  Created by Tim Oliver on 17/7/21.
//

import Foundation
import UIKit

/// Enum containing all of our destinations
enum AppRoute: Route {
    case viewController(number: Int)
}

// Our subclass of Router to contain our custom presentation logic
public class AppRouter: Router {

    override func show(_ route: Route,
                       from sourceViewController: UIViewController?) -> Bool {
        // We're only interested in routes from the AppRoute enum
        guard let appRoute = route as? AppRoute else { return false }

        // Check which enum was requested and produce a view controller for it
        switch appRoute {
        case .viewController(let number):
            let newViewController = ViewController(number: number)
            sourceViewController?
                .navigationController?
                .pushViewController(newViewController, animated: true)
        }

        return true
    }
}
