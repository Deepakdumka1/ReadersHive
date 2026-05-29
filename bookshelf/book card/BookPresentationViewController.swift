//
//  BookPresentationViewController.swift
//  Club
//
//  Created by Pawan Bisht on 13/03/26.
//

import UIKit

class BookPresentationViewController: UIViewController {
    var book: Book?
    var bookshelfData: BookshelfData!

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadBookCard()
        
        closeButton.configuration?.cornerStyle = .capsule
        shareButton.configuration?.cornerStyle = .capsule
        
        if let book = book {
            updateBackgroundColor(for: book)
        }
    }
    
    private func updateBackgroundColor(for book: Book) {
        // If it's a local image name
        if let image = UIImage(named: book.coverImageURL) {
            self.view.backgroundColor = getAverageColor(from: image)
            return
        }
        
        // If it's a URL
        guard let url = URL(string: book.coverImageURL.replacingOccurrences(of: "http://", with: "https://")) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            let color = self?.getAverageColor(from: image) ?? .systemBackground
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3) {
                    self?.view.backgroundColor = color
                }
            }
        }.resume()
    }
    func getAverageColor(from image: UIImage) -> UIColor {
        guard let inputImage = CIImage(image: image) else { return .systemBackground }
        
        let extentVector = CIVector(
            x: inputImage.extent.origin.x,
            y: inputImage.extent.origin.y,
            z: inputImage.extent.size.width,
            w: inputImage.extent.size.height
        )
        
        guard let filter = CIFilter(name: "CIAreaAverage",
                                    parameters: [
                                        kCIInputImageKey: inputImage,
                                        kCIInputExtentKey: extentVector
                                    ]) else {
            return .systemBackground
        }
        
        guard let outputImage = filter.outputImage else { return .systemBackground }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()
        
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil)
        
        return UIColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: 1
        )
    }
    func loadBookCard() {

        guard let card = Bundle.main.loadNibNamed(
            "bookCardUIView",
            owner: self,
            options: nil
        )?.first as? bookCardUIView else {
            print("Card not found")
            return
        }

        card.frame = view.bounds
        card.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(card)

        card.bookshelfData = bookshelfData
        if let book = book {
            card.configure(with: book)
        }
        
        // Ensure close & share buttons stay above the expanded content panel
        if let close = closeButton { view.bringSubviewToFront(close) }
        if let share = shareButton { view.bringSubviewToFront(share) }
    }


}
