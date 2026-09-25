//
//  BeelineTests.swift
//  BeelineTests
//
//  Created by Tim Oliver on 20/7/21.
//

import XCTest
import UIKit
#if SWIFT_PACKAGE
import Beeline
#endif

// Create a dummy destination to test
enum TestRoute: Route {
    case first
}

// Create a subclass of Router with an external closure to test
class TestRouter: Router {
    var showResultsClosure: ((Route) -> Void)?
    var acceptsRoute = true
    var receivedSource: UIViewController?
    var requestCount = 0

    override func show(_ route: Route, from sourceViewController: UIViewController?) -> Bool {
        requestCount += 1
        receivedSource = sourceViewController
        showResultsClosure?(route)
        return acceptsRoute
    }
}

class BeelineTests: XCTestCase {

    override func tearDown() {
        // Set the default class back to nil just in case
        Router.registerDefaultClass(nil)
        Router.unhandledRouteHandler = nil
        super.tearDown()
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
        let parentViewController = UINavigationController(rootViewController: viewController)
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
        let viewController = UIViewController()
        let parentViewController = UINavigationController(rootViewController: viewController)

        // Call show on the child, which will auto-generate a router on the nav controller
        viewController.show(TestRoute.first)

        // Check the expected output was correct
        XCTAssertNotNil(parentViewController.router)
        XCTAssertTrue(parentViewController.router is TestRouter)
    }

    // Real presentations require the example app host, absent in SwiftPM tests.
    #if !SWIFT_PACKAGE
    @MainActor
    func testPresentedNavigationControllerReachesExistingRouter() {
        withPresentedNavigationController { root, modal, child in
            let router = TestRouter()
            root.router = router
            Router.registerDefaultClass(TestRouter.self)

            XCTAssertTrue(child.show(TestRoute.first))
            XCTAssertEqual(router.requestCount, 1)
            XCTAssertTrue(router.receivedSource === child)
            XCTAssertNil(modal.router, "Do not create a default router before searching presenters")
        }
    }

    #endif

    func testAcceptedRouteReturnsTrueAndStopsAtNearestRouter() {
        let child = UIViewController()
        let root = UINavigationController(rootViewController: child)
        let local = TestRouter()
        let outer = TestRouter()
        child.router = local
        root.router = outer
        Router.unhandledRouteHandler = { _, _ in XCTFail("Accepted route reported as unhandled") }

        XCTAssertTrue(child.show(TestRoute.first))
        XCTAssertEqual(local.requestCount, 1)
        XCTAssertEqual(outer.requestCount, 0)
        XCTAssertTrue(local.receivedSource === child)
    }

    func testDecliningRouterFallsBackToAncestorWithOriginalSource() {
        let child = UIViewController()
        let root = UINavigationController(rootViewController: child)
        let local = TestRouter()
        local.acceptsRoute = false
        let outer = TestRouter()
        child.router = local
        root.router = outer

        XCTAssertTrue(child.show(TestRoute.first))
        XCTAssertEqual(local.requestCount, 1)
        XCTAssertEqual(outer.requestCount, 1)
        XCTAssertTrue(outer.receivedSource === child)
    }

    func testNoRouterReturnsFalseAndReportsOriginalRequestOnce() {
        let child = UIViewController()
        let root = UINavigationController(rootViewController: child)
        var reports = 0
        Router.unhandledRouteHandler = { route, source in
            reports += 1
            XCTAssertEqual(route as? TestRoute, .first)
            XCTAssertTrue(source === child)
        }

        XCTAssertFalse(child.show(TestRoute.first))
        XCTAssertEqual(reports, 1)
        XCTAssertNil(root.router)
    }

    func testAllRoutersDeclineAndReportOnce() {
        let child = UIViewController()
        let root = UINavigationController(rootViewController: child)
        let local = TestRouter()
        let outer = TestRouter()
        local.acceptsRoute = false
        outer.acceptsRoute = false
        child.router = local
        root.router = outer
        var reports = 0
        Router.unhandledRouteHandler = { _, _ in reports += 1 }

        XCTAssertFalse(child.show(TestRoute.first))
        XCTAssertEqual(local.requestCount, 1)
        XCTAssertEqual(outer.requestCount, 1)
        XCTAssertEqual(reports, 1)
    }

    func testDefaultRouterIsReused() {
        Router.registerDefaultClass(TestRouter.self)
        let child = UIViewController()
        let root = UINavigationController(rootViewController: child)

        XCTAssertTrue(child.show(TestRoute.first))
        let router = root.router as? TestRouter
        XCTAssertTrue(child.show(TestRoute.first))
        XCTAssertTrue(root.router === router)
        XCTAssertEqual(router?.requestCount, 2)
        XCTAssertTrue(router?.rootViewController === root)
    }

    func testClearingDefaultRegistrationLeavesRequestUnhandled() {
        Router.registerDefaultClass(TestRouter.self)
        Router.registerDefaultClass(nil)
        let child = UIViewController()
        XCTAssertFalse(child.show(TestRoute.first))
        XCTAssertNil(child.router)
    }

    #if !SWIFT_PACKAGE
    @MainActor
    func testContainmentOnlyLookupDoesNotReachPresenter() {
        withPresentedNavigationController { root, modal, child in
            let router = TestRouter()
            root.router = router
            XCTAssertFalse(child.show(TestRoute.first, includingPresentingViewControllers: false))
            XCTAssertEqual(router.requestCount, 0)
            XCTAssertNil(modal.router)
        }
    }

    @MainActor
    func testContainmentOnlyDefaultIsCreatedAtModalRoot() {
        withPresentedNavigationController { root, modal, child in
            Router.registerDefaultClass(TestRouter.self)
            XCTAssertTrue(child.show(TestRoute.first, includingPresentingViewControllers: false))
            XCTAssertTrue(modal.router is TestRouter)
            XCTAssertNil(root.router)
        }
    }

    @MainActor
    func testModalRouterCanDeclineToPresenter() {
        withPresentedNavigationController { root, modal, child in
            let local = TestRouter()
            local.acceptsRoute = false
            modal.router = local
            let outer = TestRouter()
            root.router = outer

            XCTAssertTrue(child.show(TestRoute.first))
            XCTAssertEqual(local.requestCount, 1)
            XCTAssertEqual(outer.requestCount, 1)
            XCTAssertTrue(outer.receivedSource === child)
        }
    }

    @MainActor
    func testModalRouterCanAcceptBeforePresenter() {
        withPresentedNavigationController { root, modal, child in
            let local = TestRouter()
            modal.router = local
            let outer = TestRouter()
            root.router = outer

            XCTAssertTrue(child.show(TestRoute.first))
            XCTAssertEqual(local.requestCount, 1)
            XCTAssertEqual(outer.requestCount, 0)
        }
    }

    @MainActor
    func testDefaultIsCreatedAtEndOfPresentationSearch() {
        withPresentedNavigationController { root, modal, child in
            Router.registerDefaultClass(TestRouter.self)
            XCTAssertTrue(child.show(TestRoute.first))
            XCTAssertTrue(root.router is TestRouter)
            XCTAssertNil(modal.router)
            XCTAssertTrue((root.router as? TestRouter)?.receivedSource === child)
        }
    }

    @MainActor
    private func withPresentedNavigationController(
        _ body: (UINavigationController, UINavigationController, UIViewController) -> Void
    ) {
        let presenter = UIViewController()
        let root = UINavigationController(rootViewController: presenter)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = root
        window.makeKeyAndVisible()
        defer {
            let dismissed = expectation(description: "Modal dismissed")
            root.dismiss(animated: false) { dismissed.fulfill() }
            wait(for: [dismissed], timeout: 5)
            window.isHidden = true
        }
        let child = UIViewController()
        let modal = UINavigationController(rootViewController: child)
        modal.modalPresentationStyle = .fullScreen
        let presented = expectation(description: "Modal presented")
        DispatchQueue.main.async {
            root.present(modal, animated: false) { presented.fulfill() }
        }
        wait(for: [presented], timeout: 5)
        XCTAssertNotNil(modal.presentingViewController)
        body(root, modal, child)
    }
    #endif

}
