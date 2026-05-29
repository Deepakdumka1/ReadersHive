import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        
        FirebaseManager.shared.requireAuth { isLoggedIn in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if isLoggedIn {
                if let tabBarController = storyboard.instantiateInitialViewController() as? UITabBarController {
                    self.injectDependencies(into: tabBarController)
                    self.window?.rootViewController = tabBarController
                }
            } else {
                self.window?.rootViewController = AuthViewController()
            }
            self.window?.makeKeyAndVisible()
        }
    }
    
    func injectDependencies(into root: UIViewController) {
        if let vc = root as? MessageViewController {
            vc.dataModel = AppDependencies.shared.messageDataModel
        }
        
        if let vc = root as? ClubViewController {
            vc.clubData = AppDependencies.shared.clubData
            vc.clubdetailData = AppDependencies.shared.clubdetailData
        }
        
        if let vc = root as? BookshelfViewController {
            vc.book = AppDependencies.shared.bookshelfData
        }
        
        if let vc = root as? HomePageViewController{
            vc.feedData = AppDependencies.shared.feedData
            vc.book = AppDependencies.shared.trendingBooksData
            vc.suggestedData = AppDependencies.shared.suggestionData
        }
        
        if let vc = root as? ProfileViewController {
            vc.profile = AppDependencies.shared.profileScreenData.data?.profile
            
            let rawPosts = AppDependencies.shared.profileScreenData.data?.posts ?? []
            let mappedPosts: [FeedPost] = rawPosts.map { post in
                let authorName = post.author?.fullName ?? "User"
                
                return FeedPost(
                    id: post.id,
                    userId: post.userId,
                    name: authorName,
                    time: "Just now",
                    title: "",
                    content: post.content ?? "",
                    likeCount: post.likesCount ?? 0,
                    commentCount: post.commentsCount ?? 0,
                    isLiked: post.isLikedByCurrentUser ?? false,
                    postImage: post.imageUrl,
                    bookTitle: nil,
                    bookAuthor: nil,
                    bookCoverImage: nil,
                    localImage: nil,
                    createdAt: post.createdAt
                )
            }
            vc.posts = mappedPosts
        }

        if let nav = root as? UINavigationController {
            nav.viewControllers.forEach { injectDependencies(into: $0) }
        }

        if let tab = root as? UITabBarController {
            tab.viewControllers?.forEach { injectDependencies(into: $0) }
        }

        if let vc = root as? searchViewController {
            vc.search_book = AppDependencies.shared.bookshelfData
            vc.profileData = AppDependencies.shared.profileData
            vc.clubData = AppDependencies.shared.clubData
            vc.clubDetailData = AppDependencies.shared.clubdetailData
        }
    }
}

class AuthViewController: UIViewController {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "BookHive"
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private lazy var modeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Login", "Sign Up"])
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        return control
    }()
    
    private let fullNameField: UITextField = {
        let field = UITextField()
        field.placeholder = "Full Name"
        field.borderStyle = .roundedRect
        field.isHidden = true
        return field
    }()
    
    private let usernameField: UITextField = {
        let field = UITextField()
        field.placeholder = "Username"
        field.borderStyle = .roundedRect
        field.isHidden = true
        return field
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.placeholder = "Email Address"
        field.borderStyle = .roundedRect
        field.keyboardType = .emailAddress
        field.autocapitalizationType = .none
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.placeholder = "Password"
        field.borderStyle = .roundedRect
        field.isSecureTextEntry = true
        return field
    }()
    
    private lazy var submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        return button
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
    }
    
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(modeSegmentedControl)
        view.addSubview(stackView)
        view.addSubview(submitButton)
        
        stackView.addArrangedSubview(fullNameField)
        stackView.addArrangedSubview(usernameField)
        stackView.addArrangedSubview(emailField)
        stackView.addArrangedSubview(passwordField)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        modeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            modeSegmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            modeSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            modeSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            stackView.topAnchor.constraint(equalTo: modeSegmentedControl.bottomAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            submitButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 30),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            submitButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func modeChanged() {
        let isSignup = modeSegmentedControl.selectedSegmentIndex == 1
        fullNameField.isHidden = !isSignup
        usernameField.isHidden = !isSignup
        submitButton.setTitle(isSignup ? "Sign Up" : "Log In", for: .normal)
    }
    
    @objc private func submitTapped() {
        let isSignup = modeSegmentedControl.selectedSegmentIndex == 1
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            return
        }
        
        Task {
            do {
                if isSignup {
                    try await FirebaseManager.shared.signUp(email: email, password: password)
                    guard let userUid = Auth.auth().currentUser?.uid else { return }
                    
                    let newProfile = Profile(
                        id: userUid,
                        userId: userUid,
                        fullName: fullNameField.text ?? "",
                        username: usernameField.text ?? "",
                        bio: "Reader",
                        avatarUrl: nil,
                        visibility: "public",
                        followers: [],
                        following: []
                    )
                    try await FirebaseManager.shared.insert(collection: "profiles", item: newProfile)
                } else {
                    try await FirebaseManager.shared.signIn(email: email, password: password)
                }
                
                DispatchQueue.main.async {
                    self.dismissToApp()
                }
            } catch {
                print("❌ Auth failed: \(error)")
            }
        }
    }
    
    private func dismissToApp() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let tabBarController = storyboard.instantiateInitialViewController() as? UITabBarController else { return }
        
        if let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.injectDependencies(into: tabBarController)
            sceneDelegate.window?.rootViewController = tabBarController
        }
    }
}
