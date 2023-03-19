//
//  TaskComposeViewController.swift
//  photo-scavenger-hunt
//
//  Created by Derrick Ng on 3/18/23.
//

import UIKit

class TaskComposeViewController: UIViewController {

    @IBOutlet weak var titleField: UITextField!
    
    // When a new task is created, this closure is called, passing in the newly created task.
    var onComposeTask: ((Task) -> Void)? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func didTapDoneButton(_ sender: Any) {

        guard let title = titleField.text,
              !title.isEmpty else {
            presentEmptyFieldsAlert()
            return
        }

        let task = Task(title: title)
        onComposeTask?(task)
        dismiss(animated: true)
    }

    
    @IBAction func didTapCancelButton(_ sender: Any) {
        dismiss(animated: true)
    }

    private func presentEmptyFieldsAlert() {
        let alertController = UIAlertController(
            title: "Oops...",
            message: "titleField must be filled out",
            preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)

        present(alertController, animated: true)
    }

}
