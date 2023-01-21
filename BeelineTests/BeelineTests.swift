//
//  BeelineTests.swift
//  BeelineTests
//
//  Created by Tim Oliver on 20/7/21.
//

import XCTest

// Create a dummy destination to test
enum TestRoute: Route {
    case first
}

// Create a subclass of Router with an external closure to test
class TestRouter: Router {
    var showResultsClosure: ((Route) -> Void)?

    override func show(_ route: Route, from sourceViewController: ViewController?) -> Bool {
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
        let viewController = ViewController()
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
        let viewController = ViewController()
#if os(iOS)
        let parentViewController = UINavigationController(rootViewController: viewController)
#elseif os(macOS)
        let parentViewController = ViewController()
        parentViewController.addChild(viewController)
#endif
        parentViewController.router = testRouter

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
        let viewController = ViewController()
#if os(iOS)
        let parentViewController = UINavigationController(rootViewController: viewController)
#elseif os(macOS)
        let parentViewController = ViewController()
        parentViewController.addChild(viewController)
#endif

        // Call show on the child, which will auto-generate a router on the nav controller
        viewController.show(TestRoute.first)

        // Check the expected output was correct
        XCTAssertNotNil(parentViewController.router)
        XCTAssertTrue(parentViewController.router is TestRouter)
    }
}
