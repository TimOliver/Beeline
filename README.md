<img src="title.png" alt="Beeline" />

<span align="center">

[![CI](https://github.com/TimOliver/Beeline/workflows/CI/badge.svg)](https://github.com/TimOliver/Beeline/actions?query=workflow%3ACI)
[![Version](https://img.shields.io/cocoapods/v/Beeline.svg?style=flat)](http://cocoadocs.org/docsets/Beeline)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/TimOliver/Beeline/main/LICENSE)
[![Platform](https://img.shields.io/cocoapods/p/Beeline.svg?style=flat)](http://cocoadocs.org/docsets/Beeline)
    
</span>

Beeline is a very small library that aims to provide a lean, automatic implementation of the classic iOS router pattern. It extends `UIViewController` to retain a `Router` object that receives navigation requests from its children and presented screens. When a child view controller wishes to transition to a new screen, it can call `show()` on itself and this request is passed up the view controller chain to the routing view controller.

# Instructions

A very basic custom implementation looks as the following. First, we create a Swift enum conforming to `Route` where we can define the types of destinations with which we want to move:

```swift
enum AppRoute: Route {
    case viewController(number: Int)
}
```
Thanks to Swift associated enums, we can also include any custom parameters the new destination may need.

We then also make a new class which subclasses `Router`, which serves as our single point of truth for controlling the app flow based off the destinations we defined above:

```swift
public class AppRouter: Router {
    public override func show(_ route: Route,
                        from sourceViewController: UIViewController?) -> Bool {

        // Optionally, filter out routes we don't support
        guard let appRoute = route as? AppRoute else { return false }

        // Check the requested enum, and perform the transition
        switch appRoute {
        case .viewController(let number):
            guard let navigationController = rootViewController as? UINavigationController,
                  navigationController.presentedViewController == nil,
                  navigationController.transitionCoordinator == nil else { return false }
            let newViewController = ViewController(number: number)
            navigationController.pushViewController(newViewController, animated: true)
        }

        return true
    }
}

```

Using Objective-C associated objects, we can assign this router to any parent view controller that contains all of the view controllers that might want to perform these transitions:

```swift
let navigationController = UINavigationController(rootViewController: ViewController())
navigationController.router = AppRouter()
```

Finally, without any further modification to any of the child view controllers, they can start a transition by simply calling `show()` with the desired destination:

```swift
class ViewController: UIViewController {
    func moveToNewViewController() {
        show(AppRoute.viewController(number: 2))
    } 
} 
```

And that's the entire library! 🎉

# Routing behavior

Call routing APIs on the main thread. `show` starts at the calling controller and searches its containment parents. At the top of each containment chain, it continues through the presenting controller. The nearest router gets the first opportunity to accept a route; returning `false` passes it onward. The original calling controller is preserved as `sourceViewController` throughout the search.

For a flow that should search only its containment hierarchy, opt out of presentation fallback:

```swift
show(AppRoute.viewController(number: 2), includingPresentingViewControllers: false)
```

`show` returns `true` when a router accepts responsibility for the request, and `false` when every router declines it or no router exists. The result is discardable, so existing call sites can keep ignoring it. Acceptance does **not** mean an animated transition has completed.

```swift
let accepted = show(AppRoute.viewController(number: 2))
```

An optional diagnostic callback runs once when a request goes unhandled:

```swift
Router.unhandledRouteHandler = { route, source in
    print("Unhandled route: \(route) from \(source)")
}
```

Set the callback to `nil` to disable it. It is process-wide, so avoid capturing view controllers or scene-specific services strongly in it.

## State and transitions

Beeline delivers requests; your router owns the navigation policy. In particular, it must decide whether to reuse an existing reader, dismiss another screen, queue a request during an animation, or reject it. A router may return `true` after queuing a request if it takes responsibility for processing it. Return `false` only when declining responsibility, since another router may then handle the same request.

Use `rootViewController` as the container managed by a router; `sourceViewController` identifies the requester and may belong to a different, presented navigation stack. The example declines requests while its container has a presented screen or active transition. A comic app can instead dismiss or wait, then open the reader in the completion callback. Beeline does not serialize transitions or deduplicate routes automatically.

## Dependencies and router creation

Assigning a router explicitly is recommended. This lets your own router initializer receive services or screen factories before any screens are created, and gives each window or flow its own router instance. A router should belong to one controller at a time.

For simple routers that can be constructed with `init()`, `Router.registerDefaultClass(AppRouter.self)` remains available. A default router is created only at the end of the selected search path when that controller has no router. In particular, presentation fallback searches for the existing app router before creating a default. Pass `nil` to clear the registration. This registration is process-wide; it does not create a single shared router instance.

## Compatibility

Presentation fallback is enabled by default. Use `includingPresentingViewControllers: false` to retain containment-only lookup. Detached controllers have no hierarchy to search, so explicitly assign a router or submit the route to an existing router when routing before attachment.

# Requirements
* Swift 5
* UIKit-compatible platforms (iOS, tvOS, Mac Catalyst)

# Installation

Beeline is a very small framework, with all of its code contained in `Router.swift`. You can install it in the following ways:

## Manual Installation

Drag the `Beeline/Router.swift` file into your Xcode project.

### CocoaPods

```
pod 'Beeline'
```

### SPM

You can add Beeline to an Xcode project by adding it as a package dependency.

https://github.com/TimOliver/Beeline

or, add the following to the dependencies in package.swift.

```swift
dependencies: [
  .package(url: "https://github.com/TimOliver/Beeline", from: "1.0.2")
]
```

### Carthage

No plans to support Carthage at the moment, but please consider filing a PR if you would like it!

# Credits

Beeline was built as a component of iComics 2 by [Tim Oliver](https://twitter.com/TimOliverAU)

# License

Beeline is available under the MIT License. Please check the [LICENSE](LICENSE) file for more information.
