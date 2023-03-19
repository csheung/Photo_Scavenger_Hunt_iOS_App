//
//  Task.swift
//  photo-scavenger-hunt
//
//  Created by Derrick Ng on 3/18/23.
//

import UIKit
import CoreLocation

class Task {
    let title: String
    var image: UIImage?
    var imageLocation: CLLocation?
    var isComplete: Bool {
        image != nil
    }

    init(title: String) {
        self.title = title
    }

    func set(_ image: UIImage, with location: CLLocation) {
        self.image = image
        self.imageLocation = location
    }
}

extension Task {
    static var mockedTasks: [Task] {
        return [
            Task(title: "My favourite city"),
            Task(title: "My favourite skiing spot"),
            Task(title: "My favourite park"),
            Task(title: "My go-to brunch place")
        ]
    }
}
