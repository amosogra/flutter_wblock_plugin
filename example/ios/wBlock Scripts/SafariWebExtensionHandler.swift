//
//  SafariWebExtensionHandler.swift
//  wBlock Scripts
//
//  Created by Amos Ogra on 01/08/2025.
//

import wBlockCoreService
import Foundation

public class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    public func beginRequest(with context: NSExtensionContext) {
        WebExtensionRequestHandler.beginRequest(with: context)
    }
}
