#!/usr/bin/swift

// Script to create light gray launch images for wBlock

import Cocoa

func createLaunchImage(width: Int, height: Int, filename: String) {
    // Create an image with light gray background (#F5F5F7)
    let image = NSImage(size: NSSize(width: width, height: height))
    
    image.lockFocus()
    
    // Fill with light gray color
    NSColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1.0).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    
    // Optional: Add app name in center
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 72, weight: .medium),
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
print("Creating launch images in: \(currentPath)")

// Create both images
createLaunchImage(width: 1024, height: 768, filename: "LaunchImage.png")
createLaunchImage(width: 2048, height: 1536, filename: "LaunchImage@2x.png")
createLaunchImage(width: 3072, height: 2304, filename: "LaunchImage@3x.png")

print("Launch images created successfully!")
print("These images have a light gray background (#F5F5F7) to match the app theme.")
