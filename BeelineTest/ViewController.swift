//
//  ViewController.swift
//  BeelineTest
//
//  Created by Tim Oliver on 17/7/21.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var numberLabel: UILabel!
    private var number: Int = 0

    init(number: Int) {
        super.init(nibName: "ViewController", bundle: nil)
        self.number = number
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.numberLabel.text = String(number)
    }

    @IBAction func buttonTapped(_ sender: Any) {
        // Tell the router to show another view controller
        show(AppRoute.viewController(number: number + 1))
    }
}
