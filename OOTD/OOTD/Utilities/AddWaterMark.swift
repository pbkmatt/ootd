import UIKit

extension UIImage {
    func addWatermark(username: String, fontName: String = "BebasNeue-Regular", fontSize: CGFloat, textColor: UIColor = .white) -> UIImage {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(size, false, scale)

        // Draw the original image
        self.draw(in: CGRect(origin: .zero, size: size))

        // Set up the watermark text
        let text = "OOTD/\(username)"
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]

        // Calculate the text size and position in the bottom-right corner
        let textSize = text.size(withAttributes: attributes)
        let padding: CGFloat = size.width * 0.03 // Dynamic padding based on image width
        let textRect = CGRect(
            x: size.width - textSize.width - padding,
            y: size.height - textSize.height - padding,
            width: textSize.width,
            height: textSize.height
        )

        // Draw the watermark text
        text.draw(in: textRect, withAttributes: attributes)

        // Retrieve the new image with the watermark
        let watermarkedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return watermarkedImage ?? self
    }
}
