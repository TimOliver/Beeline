//
//  Router.swift
//
//  Copyright 2021 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

/// A router receives navigation requests from a view controller hierarchy.
/// Instead of screens constructing destinations and performing transitions,
/// requests travel through containment parents and, by default, presenters.
/// The first router to accept a request takes responsibility for handling it.
///
/// Subclasses own navigation state, transition sequencing, and destination reuse.
/// Beeline delivers requests synchronously; it does not serialize animations.
/// Access routers and their configuration on the main thread.
///
/// `Router` is an abstract class that when subclassed, allows you to receive
/// transition requests from child view controllers, and to have a single place
/// to determine how the current state should transition to the requested one.
///
open class Router: NSObject {

    /// A reference back to the view controller to which this router is assigned.
    public internal(set) weak var rootViewController: UIViewController?

    /// Called once when a UIViewController.show request is declined by every
    /// router, or no router is found. Receives the original route and source.
    /// This process-wide diagnostic callback is nil by default. Avoid strongly
    /// capturing view controllers; configure and use it on the main thread.
    public static var unhandledRouteHandler: ((Route, UIViewController) -> Void)?

    /// Normally view controllers that should serve as a router should have
    /// their router property manually configured. But for convenience, it is also
    /// possible to define a "default" router class. If a view controller calls `show`
    /// and reaches the end of its selected search path with no router on that
    /// controller, it will instantiate and configure one there. The subclass
    /// must support construction with init(). Prefer explicit router instances
    /// when an initializer needs dependencies. Registration is process-wide.
    /// - Parameter routerClass: The class (as `Class.self`) that should created by default. Must be a subclass of `Router`.
    public class func registerDefaultClass(_ routerClass: AnyClass?) {
        // If nil was supplied, clear the currently registered class
        guard let routerClass = routerClass else {
            defaultRouterClass = nil
            return
        }

        // Ensure that the provided class is actually a subclass of Router
        guard routerClass.isSubclass(of: Router.self) else {
            fatalError("Router: Default router classes must be a subclass of the Router class.")
        }

        // Assign it as our global router
        defaultRouterClass = routerClass
    }

    /// Transitions the current view controller state of the view controller
    /// associated with this router object to the requested route destination.
    /// Override `show` in your subclasses in order to receive and perform
    /// the necessary transitions between screens that you want in your application
    /// - Parameters:
    ///   - route: A custom object conforming to the `Route` protocol used to identify the intended destination of this transition
    ///   - sourceViewController: The view controller that created this request (can be nil if the router itself directly called it)
    /// - Returns: True if this router accepts responsibility, including queuing
    ///   the request; false to let an ancestor try. Acceptance does not indicate
    ///   transition completion. Do not perform a transition and then return false.
    open func show(_ route: Route, from sourceViewController: UIViewController?) -> Bool {
        fatalError("Router: This class must be subclassed and cannot be used directly.")
    }
}

/// A route is a protocol which identifies any kind of object that can represent
/// a new routing destination to a router. Any type of object can be made to conform to
/// `Route`, and when submitted to a router, its type can then be checked
/// by the custom overrided logic in that router's `show` method to determine what to do.
public protocol Route { }

// MARK: - UIKit Integration -

public extension UIViewController {

    /// A router object that is associated with this
    /// view controller. This router will capture all of the
    /// 'show' events sent upwards from child view controllers
    var router: Router? {
        get { objc_getAssociatedObject(self, &routerKey) as? Router }
        set {
            newValue?.rootViewController = self
            objc_setAssociatedObject(self, &routerKey,
                                     newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    /// Sends a route to the nearest router willing to accept it.
    /// Searches self, then containment parents, then (by default) presenters.
    /// Call on the main thread. The original source is preserved at every step.
    /// - Parameters:
    ///   - route: The requested destination and its associated parameters.
    ///   - includingPresentingViewControllers: Whether to continue through a
    ///     presenter when a controller has no containment parent. Defaults to true.
    /// - Returns: True if a router accepted the request, not necessarily completed
    ///   a transition. False invokes Router.unhandledRouteHandler, if configured.
    @discardableResult
    func show(_ route: Route, includingPresentingViewControllers: Bool = true) -> Bool {
        var viewController: UIViewController? = self

        while let current = viewController {
            let next = current.parent ?? (includingPresentingViewControllers
                ? current.presentingViewController : nil)

            // Do not create a default at a modal boundary before searching
            // for an existing router on its presenter.
            if next == nil, current.router == nil,
               let objectClass = defaultRouterClass as? NSObject.Type {
                current.router = objectClass.init() as? Router
            }

            if let router = current.router, router.show(route, from: self) {
                return true
            }
            viewController = next
        }

        Router.unhandledRouteHandler?(route, self)
        return false
    }
}

// MARK: - Private Global Properties -

// An associated key value for storing routers inside view controllers
private var routerKey: UInt8 = 0

// Optionally, a default Router subclass that can be deferred to by default
private var defaultRouterClass: AnyClass?
