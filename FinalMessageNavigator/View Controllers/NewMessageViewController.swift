//
//  NewMessageViewController.swift
//  FinalMessageNavigator
//
//  Created by GEU on 16/02/26.
//

import UIKit

class NewMessageViewController: UIViewController {

    @IBOutlet weak var searchUserField: UITextField!
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    

}
