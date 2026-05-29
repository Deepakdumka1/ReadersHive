import UIKit

class bookCardUIView: UIView {
    var book: Book?
    var bookshelfData: BookshelfData!
    
    // MARK: - IBOutlets (existing XIB connections)
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var fantasy: UIButton!
    @IBOutlet weak var romance: UIButton!
    @IBOutlet weak var scifi: UIButton!
    @IBOutlet weak var Booklist: UIButton!
    
    // MARK: - Expand/Collapse State
    private var isExpanded = false
    private var discussionStore: BookDiscussionStore?
    private var selectedTab: Int = 0  // 0 = Overview, 1 = Community
    private var isDescriptionExpanded = false
    private var arrowImageView: UIImageView?
    private var arrowConstraints: [NSLayoutConstraint] = []
    private var coverImageViewTopConstraint: NSLayoutConstraint?
    
    // MARK: - Scroll-driven collapse state
    private var collapseAmount: CGFloat = 0.0
    private var isUpdatingLayout = false
    private var maxCollapseDistance: CGFloat {
        let safeAreaTop = self.safeAreaInsets.top > 0 ? self.safeAreaInsets.top : 47
        let dockedPanelTop = safeAreaTop + 84
        return 500.0 - dockedPanelTop
    }
    private var bookListOriginalTopConstraint: NSLayoutConstraint?
    private var bookListCenterYConstraint: NSLayoutConstraint?
    private var bookListHeightConstraint: NSLayoutConstraint?
    private var bookListWidthConstraint: NSLayoutConstraint?
    private var contentPanelTopConstraint: NSLayoutConstraint?
    
    // MARK: - Expanded Content Views (built programmatically)
    private var contentPanel: UIView?
    private var overviewTab: UIButton?
    private var communityTab: UIButton?
    private var tabIndicator: UIView?
    private var tabIndicatorLeading: NSLayoutConstraint?
    private var overviewContainer: UIView?
    private var communityContainer: UIView?
    private var discussionTableView: UITableView?
    private var filterCollectionView: UICollectionView?
    private var createButton: UIButton?
    private var descriptionLabel: UILabel?
    
    // MARK: - IBActions (existing)
    @IBAction func cardCloseTapped(_ sender: Any) {
        findViewController()?.dismiss(animated: true)
    }
    
    @objc func refreshMenu() {
        guard let book = book else { return }
        Booklist.setTitle(getShelfTitle(for: book), for: .normal)
        setupMenu()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        styleReadingButton()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshMenu),
                                               name: NSNotification.Name("bookMoved"), object: nil)
    }
    
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        if let tv = discussionTableView {
            let bottomInset = self.safeAreaInsets.bottom > 0 ? self.safeAreaInsets.bottom : 34
            tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
            tv.scrollIndicatorInsets = tv.contentInset
        }
    }
    
    // MARK: - CONFIGURE
    func configure(with book: Book) {
        self.book = book
        titleLabel.text = book.title
        authorLabel.text = book.author
        coverImageView.image = UIImage(systemName: "book")
        coverImageView.tintColor = .white
        loadImage(urlString: book.coverImageURL)
        Booklist.setTitle(getShelfTitle(for: book), for: .normal)
        setupMenu()
        discussionStore = BookDiscussionStore(bookTitle: book.title)
        discussionStore?.onDiscussionsUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.discussionTableView?.reloadData()
            }
        }
        setupExpandTrigger()
        setupCoverImageTopConstraint()
        
        let genreButtons = [fantasy, romance, scifi]
        let genres = (book.genres?.isEmpty == false) ? book.genres! : ["Fiction", "Popular", "Trending"]
        
        for (index, button) in genreButtons.enumerated() {
            if let button = button {
                if index < genres.count {
                    button.setTitle(genres[index], for: .normal)
                    button.isHidden = false
                } else {
                    button.isHidden = true
                }
            }
        }
    }
    
    private func setupCoverImageTopConstraint() {
        guard coverImageViewTopConstraint == nil else { return }
        let topConst = coverImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 92)
        self.coverImageViewTopConstraint = topConst
    }
    
    // MARK: - Expand Trigger (chevron arrow tap)
    private func setupExpandTrigger() {
        // Find the chevron.down UIImageView from XIB (arrow-img-id)
        for sub in self.subviews {
            if let iv = sub as? UIImageView, iv !== coverImageView {
                self.arrowImageView = iv
                iv.isUserInteractionEnabled = true
                let tap = UITapGestureRecognizer(target: self, action: #selector(toggleExpand))
                iv.addGestureRecognizer(tap)
                
                // Store the constraints associated with the arrowImageView
                self.arrowConstraints = self.constraints.filter {
                    $0.firstItem === iv || $0.secondItem === iv
                }
                break
            }
        }
        // Also add swipe up gesture on whole view
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(toggleExpand))
        swipe.direction = .up
        swipe.delegate = self
        self.addGestureRecognizer(swipe)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeDown.direction = .down
        swipeDown.delegate = self
        self.addGestureRecognizer(swipeDown)
    }
    
    @objc private func handleSwipeDown() {
        if isExpanded {
            toggleExpand()
        }
    }
    
    @objc private func toggleExpand() {
        isExpanded.toggle()
        
        // Deactivate cover top constraint on collapse, activate on expand
        coverImageViewTopConstraint?.isActive = isExpanded
        
        // Deactivate arrow constraints on expand, reactivate on collapse
        for constraint in arrowConstraints {
            constraint.isActive = !isExpanded
        }
        
        // Find and deactivate/reactivate Booklist top constraint
        if bookListOriginalTopConstraint == nil {
            for constraint in self.constraints {
                if (constraint.firstItem === Booklist && constraint.firstAttribute == .top) ||
                   (constraint.secondItem === Booklist && constraint.secondAttribute == .top) {
                    bookListOriginalTopConstraint = constraint
                    break
                }
            }
        }
        bookListOriginalTopConstraint?.isActive = !isExpanded
        
        // 1. Animate coverImageView height dynamically to shift elements up
        for constraint in coverImageView.constraints {
            if constraint.firstAttribute == .height {
                constraint.constant = isExpanded ? 220 : 350
            }
        }
        
        // 2. Hide/Collapse genres stack view dynamically
        if let stack = fantasy.superview as? UIStackView {
            stack.isHidden = isExpanded
            for constraint in stack.constraints {
                if constraint.firstAttribute == .height {
                    constraint.constant = isExpanded ? 0 : 44
                }
            }
        }
        
        // 3. Hide chevron image view when expanded
        arrowImageView?.isHidden = isExpanded
        
        // 4. Build or prepare to remove content panel
        if isExpanded {
            // Find width and height constraints of Booklist
            for constraint in Booklist.constraints {
                if constraint.firstAttribute == .height {
                    self.bookListHeightConstraint = constraint
                } else if constraint.firstAttribute == .width {
                    self.bookListWidthConstraint = constraint
                }
            }
            
            buildContentPanel()
            
            // Activate the Booklist centerY constraint programmatically
            if bookListCenterYConstraint == nil {
                bookListCenterYConstraint = Booklist.centerYAnchor.constraint(equalTo: self.topAnchor, constant: 450)
            }
            bookListCenterYConstraint?.isActive = true
        } else {
            // Reset scroll collapse state
            collapseAmount = 0.0
            updateHeaderLayout(for: 0.0)
            
            bookListCenterYConstraint?.isActive = false
            bookListCenterYConstraint = nil
            
            removeContentPanel()
        }
        
        // 5. Animate everything together in a single high-fidelity, premium spring animation
        UIView.animate(withDuration: 0.45, delay: 0,
                       usingSpringWithDamping: 0.85, initialSpringVelocity: 0.5,
                       options: .curveEaseInOut, animations: {
            self.layoutIfNeeded()
        }) { [weak self] _ in
            guard let self = self else { return }
            if !self.isExpanded {
                self.contentPanel?.removeFromSuperview()
                self.contentPanel = nil
                self.communityContainer = nil
                self.discussionTableView = nil
                self.filterCollectionView = nil
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Content Panel (Expanded State)

extension bookCardUIView {
    
    private func buildContentPanel() {
        guard contentPanel == nil else { return }
        
        let panel = UIView()
        panel.backgroundColor = .white
        panel.layer.cornerRadius = 24
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.layer.masksToBounds = true
        panel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(panel)
        self.contentPanel = panel
        
        // Panel starts offscreen (aligned with bottomAnchor), then animates up
        let panelTop = panel.topAnchor.constraint(equalTo: bottomAnchor)
        NSLayoutConstraint.activate([
            panel.leadingAnchor.constraint(equalTo: leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: trailingAnchor),
            panel.bottomAnchor.constraint(equalTo: bottomAnchor),
            panelTop
        ])
        layoutIfNeeded()
        
        buildCommunityContent(in: panel)
        
        // Prepare to slide up: deactivate bottom align, set top align to absolute 500 from top of view
        panelTop.isActive = false
        let finalTop = panel.topAnchor.constraint(equalTo: self.topAnchor, constant: 500)
        self.contentPanelTopConstraint = finalTop
        finalTop.isActive = true
    }
    
    private func removeContentPanel() {
        guard let panel = contentPanel else { return }
        
        // Deactivate dynamic top constraint
        contentPanelTopConstraint?.isActive = false
        contentPanelTopConstraint = nil
        
        // Deactivate the top anchor constraint to Booklist.bottom or self.top
        for constraint in self.constraints {
            if constraint.firstItem === panel && constraint.firstAttribute == .top {
                constraint.isActive = false
            }
        }
        
        // Re-align top anchor to bottomAnchor of parent to slide it out of screen
        let panelTop = panel.topAnchor.constraint(equalTo: bottomAnchor)
        panelTop.isActive = true
    }
}

// MARK: - Community Content

extension bookCardUIView {
    
    private func buildCommunityContent(in panel: UIView) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(container)
        self.communityContainer = container
        
        // Tab Container for "Community" Tab
        let tabContainer = UIView()
        tabContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tabContainer)
        
        let communityLabel = UILabel()
        communityLabel.translatesAutoresizingMaskIntoConstraints = false
        communityLabel.text = "Community"
        communityLabel.font = .systemFont(ofSize: 18, weight: .bold)
        communityLabel.textColor = .label
        tabContainer.addSubview(communityLabel)
        
        // Dynamic theme color matching the book cover card background average color
        let themeColor: UIColor
        if let image = coverImageView.image {
            themeColor = getAverageColor(from: image)
        } else {
            themeColor = UIColor(red: 0.48, green: 0.38, blue: 0.96, alpha: 1)
        }
        
        let indicator = UIView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.backgroundColor = themeColor
        indicator.layer.cornerRadius = 2
        tabContainer.addSubview(indicator)
        
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = UIColor.systemGray5
        tabContainer.addSubview(divider)
        
        // Filter chips
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(BookFilterChipCell.self, forCellWithReuseIdentifier: BookFilterChipCell.reuseId)
        container.addSubview(cv)
        self.filterCollectionView = cv
        
        // Discussion table
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.delegate = self
        tv.dataSource = self
        tv.register(BookDiscussionCell.self, forCellReuseIdentifier: BookDiscussionCell.reuseId)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 180
        container.addSubview(tv)
        self.discussionTableView = tv
        
        let tvBottom = tv.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        tvBottom.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: panel.topAnchor, constant: 16),
            container.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: panel.bottomAnchor),
            
            tabContainer.topAnchor.constraint(equalTo: container.topAnchor),
            tabContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tabContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tabContainer.heightAnchor.constraint(equalToConstant: 44),
            
            communityLabel.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor, constant: 20),
            communityLabel.centerYAnchor.constraint(equalTo: tabContainer.centerYAnchor),
            
            indicator.topAnchor.constraint(equalTo: communityLabel.bottomAnchor, constant: 6),
            indicator.leadingAnchor.constraint(equalTo: communityLabel.leadingAnchor),
            indicator.trailingAnchor.constraint(equalTo: communityLabel.trailingAnchor),
            indicator.heightAnchor.constraint(equalToConstant: 3),
            
            divider.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),
            
            cv.topAnchor.constraint(equalTo: tabContainer.bottomAnchor, constant: 12),
            cv.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            cv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            cv.heightAnchor.constraint(equalToConstant: 36),
            
            tv.topAnchor.constraint(equalTo: cv.bottomAnchor, constant: 8),
            tv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tvBottom,
        ])
    }
    
    @objc private func createDiscussionTapped() {
        guard let vc = findViewController() else { return }
        let createVC = CreateBookDiscussionViewController()
        createVC.bookTitle = book?.title ?? ""
        createVC.delegate = self
        createVC.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = createVC.sheetPresentationController {
                sheet.detents = [.medium()]
                // sheet.prefersGrabberIndicator = true
            }
        }
        vc.present(createVC, animated: true)
    }
}

// MARK: - UICollectionView (Filter Chips)

extension bookCardUIView: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return BookDiscussionTag.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BookFilterChipCell.reuseId, for: indexPath) as! BookFilterChipCell
        let tag = BookDiscussionTag.allCases[indexPath.item]
        
        let themeColor: UIColor?
        if let image = coverImageView.image {
            themeColor = getAverageColor(from: image)
        } else {
            themeColor = nil
        }
        
        cell.configure(with: tag, isSelected: discussionStore?.selectedTag == tag, themeColor: themeColor)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tag = BookDiscussionTag.allCases[indexPath.item]
        if discussionStore?.selectedTag == tag {
            discussionStore?.selectedTag = nil  // deselect
        } else {
            discussionStore?.selectedTag = tag
        }
        collectionView.reloadData()
        discussionTableView?.reloadData()
    }
}

// MARK: - UITableView (Discussion Feed)

extension bookCardUIView: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discussionStore?.filteredDiscussions.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BookDiscussionCell.reuseId, for: indexPath) as! BookDiscussionCell
        if let d = discussionStore?.filteredDiscussions[indexPath.row] {
            cell.configure(with: d)
            cell.delegate = self
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let d = discussionStore?.filteredDiscussions[indexPath.row] else { return }
        openDiscussionDetail(d)
    }
    
    private func openDiscussionDetail(_ discussion: BookDiscussion) {
        guard let vc = findViewController() else { return }
        let detailVC = BookReplyViewController()
        detailVC.discussion = discussion
        detailVC.delegate = self
        let nav = UINavigationController(rootViewController: detailVC)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        vc.present(nav, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isExpanded, scrollView === discussionTableView, !isUpdatingLayout else { return }
        
        let yOffset = scrollView.contentOffset.y
        let limit = maxCollapseDistance
        
        if yOffset > 0 {
            if collapseAmount < limit {
                isUpdatingLayout = true
                let delta = min(yOffset, limit - collapseAmount)
                collapseAmount += delta
                updateHeaderLayout(for: collapseAmount)
                scrollView.contentOffset.y = 0
                isUpdatingLayout = false
            }
        } else if yOffset < 0 {
            if collapseAmount > 0 {
                isUpdatingLayout = true
                let delta = min(-yOffset, collapseAmount)
                collapseAmount -= delta
                updateHeaderLayout(for: collapseAmount)
                scrollView.contentOffset.y = 0
                isUpdatingLayout = false
            }
        }
    }
    
    private func updateHeaderLayout(for amount: CGFloat) {
        let safeAreaTop = self.safeAreaInsets.top > 0 ? self.safeAreaInsets.top : 47
        let dockedPanelTop = safeAreaTop + 84
        let limit = 500.0 - dockedPanelTop
        let progress = min(max(amount / limit, 0.0), 1.0)
        
        // 1. Update contentPanelTopConstraint
        contentPanelTopConstraint?.constant = 500.0 - amount
        
        // 2. Update coverImageViewTopConstraint
        coverImageViewTopConstraint?.constant = 92.0 - amount
        
        // 3. Update alphas
        coverImageView.alpha = 1.0 - progress
        titleLabel.alpha = 1.0 - (progress * 2.0)
        authorLabel.alpha = 1.0 - (progress * 2.0)
        
        // 4. Update Booklist centerY
        let targetCenterY = safeAreaTop + 42
        bookListCenterYConstraint?.constant = 450.0 - progress * (450.0 - targetCenterY)
        
        // 5. Update Booklist size
        bookListHeightConstraint?.constant = 60.0 - progress * 20.0
        bookListWidthConstraint?.constant = 300.0 - progress * 100.0
        
        // 6. Update Booklist styling
        Booklist.titleLabel?.font = .systemFont(ofSize: 18.0 - progress * 4.0, weight: .semibold)
        
        self.layoutIfNeeded()
    }
}

// MARK: - Discussion Cell Delegate

extension bookCardUIView: BookDiscussionCellDelegate {
    
    func didTapReply(on discussion: BookDiscussion) {
        openDiscussionDetail(discussion)
    }
    
    func didTapRevealSpoiler(on discussion: BookDiscussion) {
        discussionStore?.toggleSpoilerReveal(for: discussion.id)
        discussionTableView?.reloadData()
    }
    
    func didTapMoreMenu(on discussion: BookDiscussion, sourceView: UIView) {
        guard let vc = findViewController() else { return }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Report", style: .destructive, handler: nil))
        alert.addAction(UIAlertAction(title: "Share", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = sourceView
            pop.sourceRect = sourceView.bounds
        }
        vc.present(alert, animated: true)
    }
}

// MARK: - Create Discussion Delegate

extension bookCardUIView: CreateBookDiscussionDelegate {
    func didCreateBookDiscussion(content: String, tag: BookDiscussionTag, tagLabel: String, isSpoiler: Bool) {
        discussionStore?.addDiscussion(content: content, tag: tag, tagLabel: tagLabel, isSpoiler: isSpoiler)
        discussionTableView?.reloadData()
    }
}

// MARK: - Reply Delegate

extension bookCardUIView: BookReplyDelegate {
    func didPostReply(to discussionId: String, content: String) {
        discussionStore?.addReply(to: discussionId, content: content)
        discussionTableView?.reloadData()
    }
}

// MARK: - Color Helpers (PRESERVED FROM ORIGINAL)

extension bookCardUIView {
    
    func getAverageColor(from image: UIImage) -> UIColor {
        guard let inputImage = CIImage(image: image) else { return .systemBackground }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y,
                                     z: inputImage.extent.size.width, w: inputImage.extent.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage",
                                    parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]),
              let outputImage = filter.outputImage else { return .systemBackground }
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        return UIColor(red: CGFloat(bitmap[0])/255, green: CGFloat(bitmap[1])/255,
                       blue: CGFloat(bitmap[2])/255, alpha: 1)
    }
    
    func applyDynamicBackground() {
        guard let image = coverImageView.image else { return }
        applyFlatBackground(with: makeExactBeige(getAverageColor(from: image)))
    }
    
    func makeExactBeige(_ color: UIColor) -> UIColor {
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        color.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
        return UIColor(hue: hue, saturation: max(sat, 0.25),
                       brightness: min(max(bri, 0.55), 0.75), alpha: 1)
    }
    
    func applyFlatBackground(with color: UIColor) {
        self.layer.sublayers?.removeAll(where: { $0.name == "bgGradient" })
        self.backgroundColor = color
    }
    
    func isLightColor(_ color: UIColor) -> Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r * 299 + g * 587 + b * 114) / 1000 > 0.8
    }
    
    func darkerColor(from color: UIColor, amount: CGFloat = 0.25) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: max(r-amount, 0), green: max(g-amount, 0), blue: max(b-amount, 0), alpha: a)
    }
    
    func lighterColor(from color: UIColor, amount: CGFloat = 0.2) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: min(r+amount, 1), green: min(g+amount, 1), blue: min(b+amount, 1), alpha: a)
    }
}

// MARK: - Image Loading (PRESERVED)

extension bookCardUIView {
    
    func loadImage(urlString: String) {
        if let localImage = UIImage(named: urlString) {
            self.coverImageView.image = localImage
            self.applyDynamicBackground()
            return
        }
        
        let secureURL = urlString.replacingOccurrences(of: "http://", with: "https://")
        guard let url = URL(string: secureURL) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.coverImageView.image = image
                self?.applyDynamicBackground()
            }
        }.resume()
    }
}

// MARK: - Shelf Logic (PRESERVED)

extension bookCardUIView {
    
    func getShelfTitle(for book: Book) -> String {
        for section in bookshelfData.sections {
            if section.books.contains(where: { $0.id == book.id }) { return section.title }
        }
        return "Add to Shelf"
    }
    
    func styleReadingButton() {
        Booklist.layer.cornerRadius = 16
        Booklist.layer.borderWidth = 2
        Booklist.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        Booklist.setTitleColor(.white, for: .normal)
        Booklist.backgroundColor = .clear
    }
    
    func moveBookToSection(_ section: ShelfSection) {
        guard let book = book else { return }
        
        // Use the centralized move method which handles cache and persistence
        bookshelfData.move(book: book, to: section.shelfType)
        
        Booklist.setTitle(section.title, for: .normal)
        // Notification is already posted by bookshelfData.move
    }
    
    func setupMenu() {
        guard let book = book else { return }
        let currentShelf = getShelfTitle(for: book)
        var actions: [UIAction] = []
        for section in bookshelfData.sections {
            let action = UIAction(title: section.title,
                                  state: (currentShelf == section.title) ? .on : .off) { [weak self] _ in
                self?.moveBookToSection(section)
            }
            actions.append(action)
        }
        Booklist.menu = UIMenu(title: "Add to Shelf", children: actions)
        Booklist.showsMenuAsPrimaryAction = true
    }
}

// MARK: - Utility (PRESERVED)

extension bookCardUIView {
    
    func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let vc = next as? UIViewController { return vc }
            responder = next
        }
        return nil
    }
    
    func navigateToClub(named clubName: String) {
        guard let presentingVC = findViewController() else { return }
        
        guard let topNav = getTopNavigationController() else {
            print("Could not find top navigation controller")
            return
        }
        
        let clubs = AppDependencies.shared.clubData.allClubs
        let matchingClub = clubs.first(where: { ($0.name ?? "").lowercased() == clubName.lowercased() }) ?? Club(
            id: "mock_club_\(UUID().uuidString.prefix(6))",
            name: clubName,
            category: .fantasy,
            description: "A community for discussions about '\(clubName)'. Join us to meet other readers, review themes, and share feedback!",
            imagePath: "https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=1000",
            memberCount: 24,
            language: "English",
            members: [],
            section: .recommended,
            createdBy: "system",
            visibility: "public"
        )
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "KafkaViewController") as? KafkaViewController else { return }
        vc.club = matchingClub
        vc.clubId = matchingClub.id ?? ""
        vc.clubData = AppDependencies.shared.clubData
        vc.clubDetailData = AppDependencies.shared.clubdetailData
        
        presentingVC.dismiss(animated: true) {
            topNav.pushViewController(vc, animated: true)
        }
    }
    
    func getTopNavigationController() -> UINavigationController? {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            return nil
        }
        
        if let tabBarVC = rootVC as? UITabBarController {
            if let navVC = tabBarVC.selectedViewController as? UINavigationController {
                return navVC
            }
            return tabBarVC.selectedViewController?.navigationController
        } else if let navVC = rootVC as? UINavigationController {
            return navVC
        }
        return nil
    }
}

// MARK: - Create Discussion Delegate & View Controller

protocol CreateBookDiscussionDelegate: AnyObject {
    func didCreateBookDiscussion(content: String, tag: BookDiscussionTag, tagLabel: String, isSpoiler: Bool)
}

class CreateBookDiscussionViewController: UIViewController {
    
    var bookTitle: String = ""
    weak var delegate: CreateBookDiscussionDelegate?
    
    private var selectedTag: BookDiscussionTag = .theme
    
    // MARK: - UI Elements
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "New Discussion"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private let bookLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let textView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = .systemFont(ofSize: 16)
        tv.layer.cornerRadius = 12
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return tv
    }()
    
    private let spoilerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Contains Spoilers"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        return label
    }()
    
    private let spoilerSwitch: UISwitch = {
        let sw = UISwitch()
        sw.translatesAutoresizingMaskIntoConstraints = false
        sw.onTintColor = UIColor(red: 0.48, green: 0.38, blue: 0.96, alpha: 1)
        return sw
    }()
    
    private let postButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Post", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = UIColor(red: 0.48, green: 0.38, blue: 0.96, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let tagStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillProportionally
        return stack
    }()
    
    private let tagScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        bookLabel.text = "Discussing: \(bookTitle)"
        setupTags()
        
        postButton.addTarget(self, action: #selector(postTapped), for: .touchUpInside)
    }
    
    // MARK: - Setup
    
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(bookLabel)
        view.addSubview(textView)
        view.addSubview(tagScrollView)
        tagScrollView.addSubview(tagStackView)
        view.addSubview(spoilerLabel)
        view.addSubview(spoilerSwitch)
        view.addSubview(postButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            bookLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            bookLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            textView.topAnchor.constraint(equalTo: bookLabel.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 120),
            
            tagScrollView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            tagScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tagScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tagScrollView.heightAnchor.constraint(equalToConstant: 40),
            
            tagStackView.topAnchor.constraint(equalTo: tagScrollView.topAnchor),
            tagStackView.leadingAnchor.constraint(equalTo: tagScrollView.leadingAnchor),
            tagStackView.trailingAnchor.constraint(equalTo: tagScrollView.trailingAnchor),
            tagStackView.bottomAnchor.constraint(equalTo: tagScrollView.bottomAnchor),
            tagStackView.heightAnchor.constraint(equalTo: tagScrollView.heightAnchor),
            
            spoilerLabel.topAnchor.constraint(equalTo: tagScrollView.bottomAnchor, constant: 20),
            spoilerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            spoilerSwitch.centerYAnchor.constraint(equalTo: spoilerLabel.centerYAnchor),
            spoilerSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            postButton.topAnchor.constraint(equalTo: spoilerLabel.bottomAnchor, constant: 24),
            postButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            postButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            postButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    private func setupTags() {
        for tag in BookDiscussionTag.allCases {
            var config = UIButton.Configuration.filled()
            config.title = tag.rawValue
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            config.cornerStyle = .capsule
            
            let button = UIButton(configuration: config, primaryAction: nil)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tag = BookDiscussionTag.allCases.firstIndex(of: tag) ?? 0
            button.addTarget(self, action: #selector(tagTapped(_:)), for: .touchUpInside)
            updateTagButtonStyle(button, isSelected: tag == selectedTag)
            tagStackView.addArrangedSubview(button)
        }
    }
    
    private func updateTagButtonStyle(_ button: UIButton, isSelected: Bool) {
        if isSelected {
            button.configuration?.baseBackgroundColor = UIColor(red: 0.48, green: 0.38, blue: 0.96, alpha: 1)
            button.configuration?.baseForegroundColor = .white
        } else {
            button.configuration?.baseBackgroundColor = .systemGray6
            button.configuration?.baseForegroundColor = .label
        }
    }
    
    @objc private func tagTapped(_ sender: UIButton) {
        let index = sender.tag
        selectedTag = BookDiscussionTag.allCases[index]
        
        for case let button as UIButton in tagStackView.arrangedSubviews {
            updateTagButtonStyle(button, isSelected: button.tag == index)
        }
    }
    
    @objc private func postTapped() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let tagLabel = "\(bookTitle) \(selectedTag.rawValue)"
        delegate?.didCreateBookDiscussion(content: text, tag: selectedTag, tagLabel: tagLabel, isSpoiler: spoilerSwitch.isOn)
        dismiss(animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension bookCardUIView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let swipe = gestureRecognizer as? UISwipeGestureRecognizer {
            let point = swipe.location(in: self)
            if isExpanded, let panel = contentPanel, panel.frame.contains(point) {
                if swipe.direction == .up {
                    return false
                }
                if swipe.direction == .down {
                    if let tv = discussionTableView, tv.contentOffset.y <= 0 {
                        return true
                    }
                    return false
                }
            }
        }
        return true
    }
}
