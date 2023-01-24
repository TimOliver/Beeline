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

/// A router is an object that is used to serve as the single source
/// of truth when dealing with the navigation flow of screens in complex
/// applications. Instead of child screens setting up and performing the transitions
/// themselves, 'show' requests are dispatched up the view controller chain
/// to a parent view controller with a router assigned, that will then perform its
/// own business logic on what action to perform.
///
/// `Router` is an abstract class that when subclassed, allows you to receive
/// transition requests from child view controllers, and to have a single place
/// to determine how the current state should transition to the requested one.
///
open class Router: NSObject {

    /// A reference back to the view controller to which this router is assigned.
    weak var rootViewController: UIViewController?

    /// Normally view controllers that should serve as a router should have
    /// their router property manually configured. But for convenience, it is also
    /// possible to define a "default" router class. If a view controller calls `show`
    /// inside a view controller chain with no router, the view controller at the top
    /// of the chain will automatically instantiate and configure one
    /// - Parameter routerClass: The class (as `Class.self`) that should created by default. Must be a subclass of `Router`.
    class func registerDefaultClass(_ routerClass: AnyClass?) {
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
    /// - Returns: Returns true if this router successfully handled the request, or false if the router decided to skip it
    func show(_ route: Route, from sourceViewController: UIViewController?) -> Bool {
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

    /// Transitions the calling view controller to the requested route destination
    /// with any associated parameters. The request is sent up the view controller
    /// chain until it reaches a view controller with an assigned router, which will
    /// then serve as the source of truth for transition
    /// - Parameter route: Any object conforming to `Route` used to uniquely identify the desired destination
    func show(_ route: Route) {
        var viewController: UIViewController? = self

        // Starting at the calling view controller, go up the parent view controller
        // chain until we find one with an associated router that will handle the transition for us
        repeat {
            // If the view controller doesn't have a parent
            // (ie, it's the top of the chain), and we have a default
            // class registered, make and assign a router to it
            if let defaultRouterClass = defaultRouterClass,
               viewController != nil, viewController!.parent == nil,
               viewController?.router == nil {
                let objectClass = defaultRouterClass as! NSObject.Type
                viewController?.router = objectClass.init() as? Router
            }

            // If this view controller has an associated router,
            // forward it the show command. If the router successfully
            // handles it, stop here. Otherwise keep going up the chain
            if let router = viewController?.router {
                if router.show(route, from: self) { return }
            }

            // Keep going up the chain until we hit the end
            viewController = viewController?.parent
        } while viewController != nil
    }
}

// MARK: - Private Global Properties -

// An associated key value for storing routers inside view controllers
private var routerKey: Void?

// Optionally, a default Router subclass that can be deferred to by default
private var defaultRouterClass: AnyClass?
