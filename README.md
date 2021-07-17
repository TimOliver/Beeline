<img src="title.png" alt="Beeline" />

Beeline is a very small library that aims to provide a lean, automatic implementation of the classic iOS router pattern. It extends `UIViewController` to retain a `Router` object that serves as the source of truth for controlling navigation flows for all of the view controller's children. When a child view controller wishes to transition to a new screen, it can call `show()` on itself and this request is passed up the view controller chain to the routing view controller.

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
	override func show(_ route: Route,
				from sourceViewController: UIViewController?) -> Bool {

	// Optionally, filter out routes we don't support
        guard let appRoute = route as? AppRoute else { return false }

        // Check the requested enum, and perform the transition
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

And that's the entire library! 😆
