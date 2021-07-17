<img src="title.png" alt="Beeline" />

Beeline is a very small library that aims to provide a lean, automatic implementation of the classic iOS router pattern. It extends `UIViewController` to retain a `Router` object that serves as the source of truth for controlling navigation flows for all of the view controller's children. When a child view controller wishes to transition to a new screen, it can call `show()` on itself and this request is passed up the view controller chain to the routing view controller.
