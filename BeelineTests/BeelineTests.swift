//
//  BeelineTests.swift
//  BeelineTests
//
//  Created by Tim Oliver on 20/7/21.
//

import XCTest
@testable import Beeline

// Create a dummy destination to test
enum TestRoute: Route {
    case first
}

// Create a subclass of Router with an external closure to test
class TestRouter: Router {
    var showResultsClosure: ((Route) -> Void)?

    override func show(_ route: Route, from sourceViewController: UIViewController?) -> Bool {
        showResultsClosure?(route)
        return true
    }
}

class BeelineTests: XCTestCase {

    override class func tearDown() {
        // Set the default class back to nil just in case
        Router.registerDefaultClass(nil)
    }

    // Test setting and getting the same router instance from a VC
    func testRouterAssigning() {
        let viewController = UIViewController()
        let testRouter = TestRouter()
        viewController.router = testRouter
        XCTAssertEqual(testRouter, viewController.router)
    }

    // Test show mechanism
    func testRouterShowCallback() {
        // Set a flag we can track
        var success = false

        // Create the router and expectation
        let testRouter = TestRouter()
        testRouter.showResultsClosure = { route in
            if let testRoute = route as? TestRoute {
                success = (testRoute == .first)
            }
        }

        // Attach the router to a view controller nested in another view controller
        let viewController = UIViewController()
        let navController = UINavigationController(rootViewController: viewController)
        navController.router = testRouter

        // Call show on the view controller
        viewController.show(TestRoute.first)

        // Capture if the call was passed back up to the router
        XCTAssertTrue(success)
    }

    // Test default mechanism
    func testRouterDefaultClass() {
        // Register the default class
        Router.registerDefaultClass(TestRouter.self)

        // Create a nested view controller setup
        let viewController = UIViewController()
        let navController = UINavigationController(rootViewController: viewController)

        // Call show on the child, which will auto-generate a router on the nav controller
        viewController.show(TestRoute.first)

        // Check the expected output was correct
        XCTAssertNotNil(navController.router)
        XCTAssertTrue(navController.router is TestRouter)
    }
}
