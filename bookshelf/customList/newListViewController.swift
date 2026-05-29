import UIKit

// ✅ Updated delegate
protocol NewListDelegate: AnyObject {
    func didCreateList(name: String, isPrivate: Bool)
}

class newListViewController: UIViewController {

    @IBOutlet weak var listNameTextField: UITextField!
    @IBOutlet weak var privateSwitch: UISwitch!   // 🔥 connect in storyboard
    
    weak var delegate: NewListDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func saveTapped1(_ sender: Any) {

        guard let name = listNameTextField.text,
              !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("❌ Empty name")
            return
        }

        let isPrivate = privateSwitch.isOn   // 🔥 key line

        // 🔥 pass both values
        delegate?.didCreateList(name: name, isPrivate: isPrivate)

        dismiss(animated: true)
    }
}
