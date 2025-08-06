#!/usr/bin/swift

// Script to create light gray launch images for wBlock iOS

import Cocoa

func createLaunchImage(width: Int, height: Int, filename: String) {
    // Create an image with iOS light gray background (#F2F2F7)
    let image = NSImage(size: NSSize(width: width, height: height))
    
    image.lockFocus()
    
    // Fill with iOS system background color
    NSColor(red: 0.949, green: 0.949, blue: 0.969, alpha: 1.0).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    
    // Optional: Add app name in center
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 60, weight: .medium),
        .foregroundColor: NSColor(red: 0, green: 0, blue: 0, alpha: 0.1) // Very light text
    ]
    
    let text = "Syferlab"
    let textSize = text.size(withAttributes: attributes)
    let textRect = NSRect(
        x: (CGFloat(width) - textSize.width) / 2,
        y: (CGFloat(height) - textSize.height) / 2,
        width: textSize.width,
        height: textSize.height
    )
    
    text.draw(in: textRect, withAttributes: attributes)
    
    image.unlockFocus()
    
    // Save as PNG
    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        
        let url = URL(fileURLWithPath: filename)
        try? pngData.write(to: url)
        print("Created \(filename)")
    }
}

// Get the current directory
let currentPath = FileManager.default.currentDirectoryPath
print("Creating iOS launch images in: \(currentPath)")

// Create iOS launch images
// Standard sizes for iOS launch images
createLaunchImage(width: 1242, height: 2688, filename: "LaunchImage.png")     // 1x (iPhone)
createLaunchImage(width: 2484, height: 5376, filename: "LaunchImage@2x.png")  // 2x (iPhone Plus/Max)
createLaunchImage(width: 3726, height: 8064, filename: "LaunchImage@3x.png")  // 3x (iPhone Pro Max)

print("iOS launch images created successfully!")
print("These images have a light gray background (#F2F2F7) to match the iOS system background.")
print("")
print("Note: iOS uses different sizes than macOS.")
print("1x: 1242x2688 (iPhone standard)")
print("2x: 2484x5376 (iPhone Plus/Max)")
print("3x: 3726x8064 (iPhone Pro Max)")
