//
//  CreateNewChatRoomViewController.swift
//  Club
//
//  Created by Manas  on 05/04/26.
//

import UIKit

protocol NewChatRoomDelegate: AnyObject {
    func didCreateChatRoom(_ chatroom: ChatRoom)
}

class CreateNewChatRoomViewController: UIViewController {


    @IBOutlet weak var Name: UITextField!
    
    @IBOutlet weak var Emoji: UITextField!
    
    weak var delegate: NewChatRoomDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        

        // Do any additional setup after loading the view.
    }
    
    @IBAction func Cancel(_ sender: Any) {
        dismiss(animated: true)
        
    }
    
    @IBAction func CreateButton(_ sender: Any) {
        guard let nameText = Name.text, !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Fallback to a default SF Symbol if the user didn't enter one
        let iconText = (Emoji.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? Emoji.text! : "message.fill"
        
        let newChatRoom = ChatRoom(
            id: UUID().uuidString,
            clubId: nil,
            title: nameText,
            icon: iconText,
            messages: []
        )
        
        // Pass data back via delegate
        delegate?.didCreateChatRoom(newChatRoom)
        dismiss(animated: true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
