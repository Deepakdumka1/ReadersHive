//
//  createPostViewController.swift
//  Club
//
//  Created by Pawan Bisht on 10/04/26.
//

import UIKit
import PhotosUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

protocol CreatePostDelegate: AnyObject {
    func didCreatePost(_ post: FeedPost)
}

class createPostViewController: UIViewController, PHPickerViewControllerDelegate {
    @IBOutlet weak var bookPreviewView: UIView!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var bookAuthorLabel: UILabel!
    @IBOutlet weak var bookCoverImageView: UIImageView!
   
    var selectedBook: Book?
    var bookshelfData: BookshelfData?
    
    var selectedImage: UIImage?
    
    let placeholderLabel = UILabel()
    
    weak var delegate: CreatePostDelegate?
    
    @IBOutlet weak var tagBookView: UIView!
    @IBOutlet weak var textView: UITextView!
    
    
    @IBAction func postTapped(_ sender: UIButton) {
        
        let contentText = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if contentText.isEmpty {
            showAlert(message: "Please write something to post")
            return
        }
        
        let currentUserUid = Auth.auth().currentUser?.uid
        
        let newPost = FeedPost(
            id: UUID().uuidString,
            userId: currentUserUid,
            name: "You",
            time: "Just now",
            title: "Shared a post",
            content: contentText,
            likeCount: 0,
            commentCount: 0,
            isLiked: false,
            postImage: nil,
            bookTitle: selectedBook?.title,
            bookAuthor: selectedBook?.author,
            bookCoverImage: selectedBook?.coverImageURL,
            localImage: selectedImage,
            bookId: selectedBook?.id
        )
        
        delegate?.didCreatePost(newPost)
        
        if let nav = navigationController {
               nav.popViewController(animated: true)
           } else {
               dismiss(animated: true)
           }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
  
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(tagBookTapped))
           tagBookView.addGestureRecognizer(tap1)
           tagBookView.isUserInteractionEnabled = true
        photoContainerView.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(addPhotoTapped))
        photoContainerView.addGestureRecognizer(tap)
    }
    
    private func setupCaptionPlaceholderLabel() {
        
        textView.isScrollEnabled = false
        textView.font = UIFont.systemFont(ofSize: 16)

     textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        textView.delegate = self
        
        placeholderLabel.text = "What's on your mind....?"
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.font = textView.font
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        textView.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 12),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 4)
        ])
    }
    
    
    func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Oops",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }


    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        dismiss(animated: true)
        
        guard let item = results.first?.itemProvider,
              item.canLoadObject(ofClass: UIImage.self) else { return }
        
        item.loadObject(ofClass: UIImage.self) { image, error in
            DispatchQueue.main.async {
                if let selectedImage = image as? UIImage {
                    self.imageView.image = selectedImage
                    self.selectedImage = selectedImage
                }
            }
        }
    }
    
    @IBOutlet weak var photoContainerView: UIView!
    
    @IBOutlet weak var imageView: UIImageView!

    @objc func tagBookTapped() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "tagBookViewController"
        ) as? tagBookViewController else {
            print("❌ VC not found")
            return
        }
       // vc.bookshelfData = bookshelfData
        
        vc.delegate = self
        
        present(vc, animated: true)
    }
  
    func openBookSelection() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "tagBookViewController"
        ) as? tagBookViewController else {
            print("❌ VC not found")
            return
        }

        vc.delegate = self

        guard self.view.window != nil else {
            print("❌ Not in view hierarchy")
            return
        }

        DispatchQueue.main.async {
            self.present(vc, animated: true)
        }
    }
    
    @objc func addPhotoTapped() {
        openImagePicker()// test first
    }
    
    func openImagePicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1 // only 1 image
        config.filter = .images   // only images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        
        present(picker, animated: true)
    }
    
    

}

extension createPostViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > 200 {
            textView.text = String(textView.text.prefix(200))
        }
    }
}


extension createPostViewController: TagBookViewControllerDelegate {
    
    func didSelectBook(_ book: Book) {
        
        selectedBook = book
        bookTitleLabel.text = book.title
        bookAuthorLabel.text = book.author
        bookCoverImageView.image = UIImage(named: book.coverImageURL)
        
        bookPreviewView.isHidden = false
    }
}
