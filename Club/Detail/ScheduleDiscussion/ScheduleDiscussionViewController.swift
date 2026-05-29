//
//  ScheduleDiscussionViewController.swift
//  demo clubpost
//
//  Created on 08/04/26.
//

import UIKit
import FirebaseAuth

// MARK: - Delegate to pass new scheduled discussion back (same pattern as NewDiscussionDelegate)
protocol NewScheduledDiscussionDelegate: AnyObject {
    func didCreateScheduledDiscussion(_ discussion: Discussion)
}

class ScheduleDiscussionViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var meetingLinkTextField: UITextField!
    @IBOutlet weak var scheduleButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var dateColumnStack: UIStackView!
    @IBOutlet weak var timeColumnStack: UIStackView!

    // MARK: - Programmatic UI

    /// Chip views (tappable labels in the date/time columns)
    private var dateChipView: UIView!
    private var dateChipLabel: UILabel!
    private var dateChevron: UIImageView!

    private var timeChipView: UIView!
    private var timeChipLabel: UILabel!
    private var timeChevron: UIImageView!

    /// Full-width picker containers inserted into mainStackView
    private var datePickerContainer: UIView!
    private var timePickerContainer: UIView!

    // MARK: - Delegate

    weak var delegate: NewScheduledDiscussionDelegate?

    // MARK: - State

    private var isDatePickerExpanded = false
    private var isTimePickerExpanded = false

    // MARK: - Formatters

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private lazy var timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    // MARK: - Constants

    private let descriptionPlaceholder = "What will you be discussing? (e.g. Dissecting K's struggle against authority...)"
    private let chipHeight: CGFloat = 48
    private let chipCornerRadius: CGFloat = 14
    private let accentColor = UIColor(red: 0.47, green: 0.337, blue: 0.855, alpha: 1.0)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildDateTimeUI()
        setupUI()
        setupKeyboardHandling()
        setupDelegates()
    }

    // MARK: - Build Date/Time Chips & Picker Containers

    private func buildDateTimeUI() {
        // ──────────────────────────────────────────────
        // 1. Remove the raw pickers from their column stacks.
        //    (Outlets still hold valid references.)
        // ──────────────────────────────────────────────
        datePicker.removeFromSuperview()
        timePicker.removeFromSuperview()

        // ──────────────────────────────────────────────
        // 2. Create chip views → add to each column stack
        //    (chips sit below the "Date" / "Time" labels)
        // ──────────────────────────────────────────────
        dateChipView = makeChipView()
        dateChipLabel = makeChipLabel(text: dateFormatter.string(from: Date()))
        dateChevron = makeChevron()
        assembleChip(container: dateChipView, label: dateChipLabel, chevron: dateChevron)
        dateChipView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(dateChipTapped))
        )
        dateColumnStack.addArrangedSubview(dateChipView)

        timeChipView = makeChipView()
        timeChipLabel = makeChipLabel(text: timeFormatter.string(from: Date()))
        timeChevron = makeChevron()
        assembleChip(container: timeChipView, label: timeChipLabel, chevron: timeChevron)
        timeChipView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(timeChipTapped))
        )
        timeColumnStack.addArrangedSubview(timeChipView)

        // ──────────────────────────────────────────────
        // 3. Configure pickers
        // ──────────────────────────────────────────────
        datePicker.preferredDatePickerStyle = .inline
        datePicker.datePickerMode = .date
        datePicker.minimumDate = Date()
        datePicker.tintColor = accentColor
        datePicker.addTarget(self, action: #selector(dateValueChanged(_:)), for: .valueChanged)

        timePicker.preferredDatePickerStyle = .wheels
        timePicker.datePickerMode = .time
        timePicker.tintColor = accentColor
        timePicker.addTarget(self, action: #selector(timeValueChanged(_:)), for: .valueChanged)

        // ──────────────────────────────────────────────
        // 4. Create FULL-WIDTH picker containers and
        //    insert them into mainStackView right after
        //    the date/time chip row (stk-da-teT).
        //
        //    Layout:
        //    ┌─ Header ─────────────────────────────┐
        //    ├─ Name ───────────────────────────────┤
        //    ├─ [ Date chip | Time chip ] ──────────┤  ← stk-da-teT
        //    ├─ Date Picker Container (full width) ─┤  ← NEW (hidden)
        //    ├─ Time Picker Container (full width) ─┤  ← NEW (hidden)
        //    ├─ Description ────────────────────────┤
        //    ├─ Meeting Link ───────────────────────┤
        //    ├─ Schedule Button ────────────────────┤
        //    └─ Spacer ─────────────────────────────┘
        // ──────────────────────────────────────────────

        // Find the date/time row in the main stack
        let dateTimeRow = dateColumnStack.superview as! UIStackView  // stk-da-teT
        guard let rowIndex = mainStackView.arrangedSubviews.firstIndex(of: dateTimeRow) else { return }

        // Date picker container
        datePickerContainer = makePickerContainer(with: datePicker)
        datePickerContainer.isHidden = true   // Stack view ignores hidden views entirely
        mainStackView.insertArrangedSubview(datePickerContainer, at: rowIndex + 1)

        // Time picker container
        timePickerContainer = makePickerContainer(with: timePicker)
        timePickerContainer.isHidden = true
        mainStackView.insertArrangedSubview(timePickerContainer, at: rowIndex + 2)

        // Tighten spacing between chip row ↔ picker containers
        mainStackView.setCustomSpacing(12, after: dateTimeRow)
        mainStackView.setCustomSpacing(8, after: datePickerContainer)
        mainStackView.setCustomSpacing(24, after: timePickerContainer)
    }

    // MARK: - Factory: Chip

    private func makeChipView() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = chipCornerRadius
        v.clipsToBounds = true
        v.isUserInteractionEnabled = true
        v.heightAnchor.constraint(equalToConstant: chipHeight).isActive = true
        return v
    }

    private func makeChipLabel(text: String) -> UILabel {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = text
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = .label
        return l
    }

    private func makeChevron() -> UIImageView {
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let iv = UIImageView(image: UIImage(systemName: "chevron.down", withConfiguration: config))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .secondaryLabel
        iv.contentMode = .scaleAspectFit
        return iv
    }

    private func assembleChip(container: UIView, label: UILabel, chevron: UIImageView) {
        container.addSubview(label)
        container.addSubview(chevron)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 14),
            chevron.heightAnchor.constraint(equalToConstant: 14),
            label.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8)
        ])
    }

    // MARK: - Factory: Picker Container (Glass Card)

    private func makePickerContainer(with picker: UIDatePicker) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.clipsToBounds = true
        container.layer.cornerRadius = 16
        container.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.4)

        // Glass blur
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(blur)

        // Picker
        picker.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(picker)

        NSLayoutConstraint.activate([
            // Blur fills container
            blur.topAnchor.constraint(equalTo: container.topAnchor),
            blur.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            // Picker fills container with padding
            picker.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            picker.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            picker.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            picker.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
        ])

        return container
    }

    // MARK: - Toggle Actions

    @objc private func dateChipTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Auto-close time if open
        if isTimePickerExpanded {
            isTimePickerExpanded = false
            animatePickerCollapse(timePickerContainer, chevron: timeChevron, chip: timeChipView)
        }

        isDatePickerExpanded.toggle()

        if isDatePickerExpanded {
            animatePickerExpand(datePickerContainer, chevron: dateChevron, chip: dateChipView)
        } else {
            animatePickerCollapse(datePickerContainer, chevron: dateChevron, chip: dateChipView)
        }
    }

    @objc private func timeChipTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Auto-close date if open
        if isDatePickerExpanded {
            isDatePickerExpanded = false
            animatePickerCollapse(datePickerContainer, chevron: dateChevron, chip: dateChipView)
        }

        isTimePickerExpanded.toggle()

        if isTimePickerExpanded {
            animatePickerExpand(timePickerContainer, chevron: timeChevron, chip: timeChipView)
        } else {
            animatePickerCollapse(timePickerContainer, chevron: timeChevron, chip: timeChipView)
        }
    }

    // MARK: - Expand / Collapse Animations

    private func animatePickerExpand(_ container: UIView, chevron: UIImageView, chip: UIView) {
        // Reveal by setting isHidden = false inside animation block.
        // UIStackView animates the height automatically.
        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.5,
            options: [.curveEaseInOut]
        ) {
            container.isHidden = false
            container.alpha = 1
            chevron.transform = CGAffineTransform(rotationAngle: .pi)
            chip.backgroundColor = self.accentColor.withAlphaComponent(0.12)
            chip.layer.borderWidth = 1.5
            chip.layer.borderColor = self.accentColor.withAlphaComponent(0.4).cgColor
            self.view.layoutIfNeeded()
        } completion: { _ in
            // Scroll the expanded picker into view
            DispatchQueue.main.async {
                let rect = container.convert(container.bounds, to: self.scrollView)
                self.scrollView.scrollRectToVisible(rect, animated: true)
            }
        }
    }

    private func animatePickerCollapse(_ container: UIView, chevron: UIImageView, chip: UIView) {
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.3,
            options: [.curveEaseInOut]
        ) {
            container.isHidden = true
            container.alpha = 0
            chevron.transform = .identity
            chip.backgroundColor = .systemGray6
            chip.layer.borderWidth = 0
            chip.layer.borderColor = nil
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Picker Value Changed

    @objc private func dateValueChanged(_ sender: UIDatePicker) {
        dateChipLabel.text = dateFormatter.string(from: sender.date)
        pulseLabel(dateChipLabel)
    }

    @objc private func timeValueChanged(_ sender: UIDatePicker) {
        timeChipLabel.text = timeFormatter.string(from: sender.date)
        pulseLabel(timeChipLabel)
    }

    private func pulseLabel(_ label: UILabel) {
        UIView.animate(withDuration: 0.12, animations: {
            label.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
        }) { _ in
            UIView.animate(withDuration: 0.12) { label.transform = .identity }
        }
    }

    // MARK: - Setup

    private func setupUI() {
        descriptionTextView.text = descriptionPlaceholder
        descriptionTextView.textColor = .placeholderText
        descriptionTextView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupDelegates() {
        nameTextField.delegate = self
        meetingLinkTextField.delegate = self
        descriptionTextView.delegate = self
    }

    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - Actions


    @IBAction func closeButtonTappedd(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func scheduleButtonTapped(_ sender: UIButton) {
        guard validateForm() else { return }

        let calendar = Calendar.current
        let dc = calendar.dateComponents([.year, .month, .day], from: datePicker.date)
        let tc = calendar.dateComponents([.hour, .minute], from: timePicker.date)

        var combined = DateComponents()
        combined.year = dc.year; combined.month = dc.month; combined.day = dc.day
        combined.hour = tc.hour; combined.minute = tc.minute

        let name = nameTextField.text ?? ""
        let desc = descriptionTextView.textColor == .placeholderText ? "" : descriptionTextView.text ?? ""
        let link = meetingLinkTextField.text ?? ""

        // Format date and time strings
        let dateString = dateFormatter.string(from: datePicker.date)
        let timeString = timeFormatter.string(from: timePicker.date)

        // Create Discussion object (same model used in scheduledDiscussions)
        let newDiscussion = Discussion(
            id: UUID().uuidString,
            clubId: nil,
            createdBy: Auth.auth().currentUser?.uid ?? currentUserId,
            title: name,
            description: desc,
            date: dateString,
            time: timeString,
            meetingLink: link.isEmpty ? nil : link,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )

        // Pass data back via delegate (same pattern as NewDiscussionDelegate)
        delegate?.didCreateScheduledDiscussion(newDiscussion)

        dismiss(animated: true)
    }

    // MARK: - Validation

    private func validateForm() -> Bool {
        guard let name = nameTextField.text,
              !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Missing Name", message: "Please enter a discussion name.")
            return false
        }
        return true
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Keyboard

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func keyboardWillShow(_ n: Notification) {
        guard let kf = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = kf.height
        scrollView.verticalScrollIndicatorInsets.bottom = kf.height
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        scrollView.contentInset = .zero
        scrollView.verticalScrollIndicatorInsets = .zero
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}

// MARK: - UITextFieldDelegate

extension ScheduleDiscussionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            meetingLinkTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - UITextViewDelegate

extension ScheduleDiscussionViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = descriptionPlaceholder
            textView.textColor = .placeholderText
        }
    }
}
