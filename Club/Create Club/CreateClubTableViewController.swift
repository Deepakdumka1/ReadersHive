import UIKit
import PhotosUI
import FirebaseAuth

class CreateClubTableViewController: UITableViewController {

    var club: Club?
    var selectedImage: UIImage?
    
    @IBOutlet weak var clubImageView: UIImageView!
    @IBOutlet weak var clubName: UITextField!
    @IBOutlet weak var clubDescription: UITextField!
    @IBOutlet weak var language: UITextField!
    @IBOutlet weak var genre: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var clubPrivacy: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       // setupTextFields()
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 13.0
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 13.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Section 0, Row 0 is the Image cell
        if indexPath.section == 0 && indexPath.row == 0 {
            DispatchQueue.main.async {
                let picker = UIImagePickerController()
                picker.delegate = self
                picker.sourceType = .photoLibrary
                picker.allowsEditing = true
                self.present(picker, animated: true, completion: nil)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard segue.identifier == "saveUnwind" else { return }
        
        let name = clubName.text ?? ""
        let desc = clubDescription.text ?? ""
        let lang = language.text ?? ""
        
        let selectedCategory = ClubCategory(rawValue: category.text ?? "")
        
        let clubId = UUID().uuidString
        let userId = Auth.auth().currentUser?.uid ?? ""
        let creator = ClubMember(
            clubId: clubId,
            userId: userId,
            role: "admin",
            joinedAt: "\(Date())",
            fullName: nil // Will be fetched if possible, but optional for now
        )
        

        
        self.club = Club(
            id: clubId,
            name: name,
            category: selectedCategory,
            description: desc,
            imagePath: "", // Will be updated after upload
            memberCount: 1,
            language: lang,
            members: [creator],
            section: .myClubs,
            createdBy: Auth.auth().currentUser?.uid,
            visibility: clubPrivacy.isOn ? "private" : "public",
            localImage: selectedImage
        )
    }
    
//    func setupTextFields() {
//        let fields = [clubName, clubDescription, language, genre, category]
//        
//        for field in fields {
//            guard let tf = field else { continue }
//            
//            tf.borderStyle = .none
//            tf.backgroundColor = UIColor.systemGray6
//            tf.layer.cornerRadius = 8
//            tf.setLeftPadding(10)
//            tf.layer.borderWidth = 1
//            tf.layer.borderColor = UIColor.systemGray5.cgColor
//        }
//    }
}

// MARK: - Padding Extension
extension UITextField {
    func setLeftPadding(_ amount: CGFloat) {
        let paddingView = UIView(
            frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.height)
        )
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension CreateClubTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            clubImageView.image = editedImage
            selectedImage = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            clubImageView.image = originalImage
            selectedImage = originalImage
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

