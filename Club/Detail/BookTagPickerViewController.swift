import UIKit

class BookTagPickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    var books: [Book] = []
    var onBookSelected: ((Book) -> Void)?
    
    private var filteredBooks: [Book] = []
    
    // MARK: - UI Elements
    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Tag a Book"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.backgroundColor = .systemBackground
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let searchContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 24
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let searchIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iv.tintColor = .secondaryLabel
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let searchTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Search books..."
        tf.font = .systemFont(ofSize: 16)
        tf.borderStyle = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        filteredBooks = books
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(dismissButton)
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(searchContainer)
        
        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchTextField)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(BookPickerCell.self, forCellReuseIdentifier: "BookPickerCell")
        
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        searchTextField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),
            dismissButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            dismissButton.widthAnchor.constraint(equalToConstant: 44),
            dismissButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerYAnchor.constraint(equalTo: dismissButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: dismissButton.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: searchContainer.topAnchor, constant: -12),
            
            searchContainer.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            searchContainer.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            searchContainer.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -16),
            searchContainer.heightAnchor.constraint(equalToConstant: 48),
            
            searchIcon.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 16),
            searchIcon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),
            
            searchTextField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 12),
            searchTextField.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -16),
            searchTextField.topAnchor.constraint(equalTo: searchContainer.topAnchor),
            searchTextField.bottomAnchor.constraint(equalTo: searchContainer.bottomAnchor)
        ])
    }
    
    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
    
    private var searchTimer: Timer?
    
    @objc private func searchChanged() {
        searchTimer?.invalidate()
        let query = searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        
        if query.isEmpty {
            filteredBooks = books
            tableView.reloadData()
        } else {
            // Wait 0.5s before hitting the API so we don't spam requests
            searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                GoogleBooksService.searchBooks(query: query) { googleBooks in
                    // Map the GoogleBook results to the standard Book model
                    self?.filteredBooks = googleBooks.map { $0.toBook() }
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - UITableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredBooks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BookPickerCell", for: indexPath) as! BookPickerCell
        cell.configure(with: filteredBooks[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = filteredBooks[indexPath.row]
        onBookSelected?(selected)
        dismiss(animated: true)
    }
}

// MARK: - BookPickerCell
class BookPickerCell: UITableViewCell {
    
    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(coverImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(authorLabel)
        
        NSLayoutConstraint.activate([
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            coverImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 48),
            coverImageView.heightAnchor.constraint(equalToConstant: 72),
            
            titleLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            titleLabel.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 8),
            
            authorLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            authorLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4)
        ])
    }
    
    func configure(with book: Book) {
        titleLabel.text = book.title
        authorLabel.text = book.author
        
        coverImageView.tintColor = .systemGray4
        if book.coverImageURL.isEmpty {
            coverImageView.image = UIImage(systemName: "book.closed.fill")
        } else {
            coverImageView.loadFromUrl(book.coverImageURL, placeholder: UIImage(systemName: "book.closed.fill"))
        }
    }
}
