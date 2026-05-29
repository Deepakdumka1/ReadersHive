//
//  ClubHeaderCell.swift
//  Club
//
//  Created by Manas  on 10/03/26.
//

import UIKit

protocol ClubHeaderCellDelegate: AnyObject {
    func didTapMemberList()
}

class ClubHeaderCell: UICollectionViewCell {
    
    

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!


    @IBOutlet weak var moderatorAvatarLabel: UILabel!

    @IBOutlet weak var avatarStackContainer: UIView!

    @IBOutlet weak var memberCountLabel: UILabel!
    
    weak var delegate: ClubHeaderCellDelegate?

      override func awakeFromNib() {
          super.awakeFromNib()
          contentView.clipsToBounds = true
          // 1. Remove rounded corners from the background image
          backgroundImageView.layer.cornerRadius = 0

          // 2. Match the blur style shown in the screenshot
          if let blurView = overlayView as? UIVisualEffectView {
              blurView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
          }
          overlayView.alpha = 0.85

//          // 2. Only round the TOP corners, leave bottom corners sharp
//          overlayView.layer.cornerRadius = 24  // keep same radius on top
//          overlayView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
//          overlayView.clipsToBounds = true
      }

      @IBAction func memberlistButon(_ sender: Any) {
          delegate?.didTapMemberList()
      }
    

    func configure(with club: ClubDetail) {
        titleLabel.text = club.club?.name
        subtitleLabel.text = club.club?.description

        if let path = club.club?.imagePath, !path.isEmpty {
            if path.hasPrefix("http") {
                backgroundImageView.loadFromUrl(path, placeholder: nil)
                // For network images, we default to dark overlay as we don't have the image yet for brightness analysis
                applyAdaptiveStyle(for: nil)
            } else if let img = UIImage(named: path) {
                backgroundImageView.image = img
                applyAdaptiveStyle(for: img)
            } else if let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = docURL.appendingPathComponent(path)
                let img = UIImage(contentsOfFile: fileURL.path)
                backgroundImageView.image = img
                applyAdaptiveStyle(for: img)
            }
        } else {
            backgroundImageView.image = nil
            applyAdaptiveStyle(for: nil)
        }

        let count = club.club?.members?.count ?? club.club?.memberCount ?? 0
        memberCountLabel.text = "+\(count) attending"
    }

      // MARK: - Adaptive Styling

      private func applyAdaptiveStyle(for image: UIImage?) {
          guard let image = image,
                let brightness = image.averageBrightness() else {
              // No image — default to dark overlay, white text
              applyStyle(isDark: true)
              return
          }

          // If image is bright (> 0.6), use dark text; otherwise use white text
          applyStyle(isDark: brightness > 0.6)
      }

    private func applyStyle(isDark: Bool) {
        if isDark {
            titleLabel.textColor = UIColor.black
            subtitleLabel.textColor = UIColor.black.withAlphaComponent(0.75)
            memberCountLabel.textColor = UIColor.black.withAlphaComponent(0.75)
            // Switch to light blur for bright backgrounds
            if let blurView = overlayView as? UIVisualEffectView {
                blurView.effect = UIBlurEffect(style: .systemMaterialLight)
            }
        } else {
            titleLabel.textColor = UIColor.white
            subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
            memberCountLabel.textColor = UIColor.white.withAlphaComponent(0.85)
            // Dark blur for dark backgrounds
            if let blurView = overlayView as? UIVisualEffectView {
                blurView.effect = UIBlurEffect(style: .systemThinMaterialDark)
            }
        }
        // ❌ Remove overlayView.backgroundColor — never set this on a UIVisualEffectView
    }
  }

  // MARK: - UIImage Brightness Extension

  extension UIImage {
      /// Samples a grid of pixels and returns average luminance (0.0 = black, 1.0 = white).
      /// Focuses on the bottom portion of the image where text typically sits.
      func averageBrightness() -> CGFloat? {
          guard let cgImage = self.cgImage else { return nil }

          let width = 40
          let height = 20
          let colorSpace = CGColorSpaceCreateDeviceRGB()
          let bytesPerPixel = 4
          let bytesPerRow = bytesPerPixel * width
          var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)

          guard let context = CGContext(
              data: &pixelData,
              width: width,
              height: height,
              bitsPerComponent: 8,
              bytesPerRow: bytesPerRow,
              space: colorSpace,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          ) else { return nil }

          // Sample only the bottom ~40% of the image where title/subtitle sit
          let sourceHeight = CGFloat(cgImage.height)
          let sampleRect = CGRect(
              x: 0,
              y: sourceHeight * 0.6,          // start at 60% down
              width: CGFloat(cgImage.width),
              height: sourceHeight * 0.4
          )

          if let croppedCG = cgImage.cropping(to: sampleRect) {
              context.draw(croppedCG, in: CGRect(x: 0, y: 0, width: width, height: height))
          } else {
              context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
          }

          var totalBrightness: CGFloat = 0
          let pixelCount = width * height

          for i in 0..<pixelCount {
              let offset = i * bytesPerPixel
              let r = CGFloat(pixelData[offset])     / 255.0
              let g = CGFloat(pixelData[offset + 1]) / 255.0
              let b = CGFloat(pixelData[offset + 2]) / 255.0
              // Perceived luminance formula (matches human vision weighting)
              totalBrightness += 0.299 * r + 0.587 * g + 0.114 * b
          }

          return totalBrightness / CGFloat(pixelCount)
      }
  }
