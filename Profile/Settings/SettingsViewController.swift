import UIKit
import FirebaseAuth
import FirebaseFirestore

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let sections = SettingsSection.allCases
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground
        
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData() // Refresh state, e.g., Message Permissions
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
    }
    
    // MARK: - Handlers
    
    @objc private func handleSwitchChange(_ sender: UISwitch) {
        // Tag maps to (section * 100) + row
        let section = sender.tag / 100
        let row = sender.tag % 100
        
        guard let sectionEnum = SettingsSection(rawValue: section) else { return }
        let rowEnum = sectionEnum.rows[row]
        
        switch rowEnum {
        case .privateAccount:
            SettingsManager.shared.isPrivateAccount = sender.isOn
        case .activityVisibility:
            SettingsManager.shared.activityVisibility = sender.isOn
        default:
            break
        }
    }
    
    private func performLogout() {
        do {
            try FirebaseManager.shared.signOut()
            
            // Redirect to Login Screen
            if let window = view.window {
                window.rootViewController = AuthViewController()
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
            }
        } catch {
            print("❌ Logout failed: \(error)")
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowEnum = sections[indexPath.section].rows[indexPath.row]
        
        // Re-dequeueing with specific style if needed, though default cell reuse works for standard layouts.
        // For value1 style, we configure it dynamically or reuse.
        let cellTitle = rowEnum.title
        
        let cell: UITableViewCell
        
        switch rowEnum {
        case .messagePermissions:
            // Needs value1 subtitle
            cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.detailTextLabel?.text = SettingsManager.shared.messagePermissions.rawValue
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = cellTitle
            
        case .editProfile, .changePassword:
            cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = cellTitle
            
        case .privateAccount, .activityVisibility:
            cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            let toggle = UISwitch()
            toggle.tag = (indexPath.section * 100) + indexPath.row
            toggle.addTarget(self, action: #selector(handleSwitchChange(_:)), for: .valueChanged)
            
            switch rowEnum {
            case .privateAccount: toggle.isOn = SettingsManager.shared.isPrivateAccount
            case .activityVisibility: toggle.isOn = SettingsManager.shared.activityVisibility
            default: break
            }
            
            cell.accessoryView = toggle
            cell.textLabel?.text = cellTitle
            
        case .logout:
            cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = cellTitle
            cell.textLabel?.textColor = .systemRed
            cell.textLabel?.textAlignment = .center
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let rowEnum = sections[indexPath.section].rows[indexPath.row]
        
        switch rowEnum {
        case .editProfile:
            navigationController?.pushViewController(EditProfileViewController(), animated: true)
            
        case .changePassword:
            navigationController?.pushViewController(SimplePlaceholderViewController(title: "Change Password"), animated: true)
            
        case .messagePermissions:
            navigationController?.pushViewController(MessagePermissionsViewController(), animated: true)
            
        case .logout:
            performLogout()
            
        case .privateAccount, .activityVisibility:
            // Do nothing, handled by UISwitch
            break
        }
    }
}

class EditProfileViewController: UIViewController {
    
    private let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Full Name"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let aboutTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.layer.borderWidth = 1
        tv.layer.cornerRadius = 8
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let aboutLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "About"
        lbl.font = .systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveTapped))
        
        setupUI()
        loadCurrentData()
    }
    
    private func setupUI() {
        view.addSubview(nameTextField)
        view.addSubview(aboutLabel)
        view.addSubview(aboutTextView)
        
        NSLayoutConstraint.activate([
            nameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            aboutLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            aboutLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            aboutTextView.topAnchor.constraint(equalTo: aboutLabel.bottomAnchor, constant: 8),
            aboutTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            aboutTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            aboutTextView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    private func loadCurrentData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("profiles").document(uid).getDocument { [weak self] snapshot, _ in
            if let profile = try? snapshot?.data(as: Profile.self) {
                DispatchQueue.main.async {
                    self?.nameTextField.text = profile.fullName
                    self?.aboutTextView.text = profile.bio ?? profile.description
                }
            }
        }
    }
    
    @objc private func saveTapped() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let newName = nameTextField.text ?? ""
        let newBio = aboutTextView.text ?? ""
        
        let updateData: [String: Any] = [
            "fullName": newName,
            "description": newBio
        ]
        
        // Show loading indicator
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        
        Firestore.firestore().collection("profiles").document(uid).updateData(updateData) { [weak self] error in
            DispatchQueue.main.async {
                self?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(self?.saveTapped))
                
                if let error = error {
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}
