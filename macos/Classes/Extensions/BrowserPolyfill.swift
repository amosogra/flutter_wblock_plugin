import Foundation

/// Browser polyfill utilities for Safari extensions
class BrowserPolyfill {
    
    /// Generate the browser API polyfill for Safari
    static func generatePolyfill() -> String {
        return """
        // Browser API polyfill for Safari
        if (typeof browser === 'undefined') {
            window.browser = window.chrome || {};
        }
        
        // Polyfill for Safari-specific APIs
        if (!browser.runtime) {
            browser.runtime = {
                sendMessage: function(message, callback) {
                    safari.extension.dispatchMessage('runtime.sendMessage', message);
                    if (callback) {
                        // Store callback for response
                        const callbackId = Date.now() + Math.random();
                        window.__wblockCallbacks = window.__wblockCallbacks || {};
                        window.__wblockCallbacks[callbackId] = callback;
                        message.__callbackId = callbackId;
                    }
                },
                
                onMessage: {
                    addListener: function(callback) {
                        safari.self.addEventListener('message', function(event) {
                            if (event.name === 'runtime.onMessage') {
                                callback(event.message, {tab: {id: 'self'}}, function(response) {
                                    safari.extension.dispatchMessage('runtime.sendResponse', {
                                        response: response,
                                        messageId: event.message.__messageId
                                    });
                                });
                            }
                        });
                    }
                },
                
                sendNativeMessage: function(application, message, callback) {
                    safari.extension.dispatchMessage('runtime.sendNativeMessage', {
                        application: application,
                        message: message
                    });
                    if (callback) {
                        // Handle response
                        const responseHandler = function(event) {
                            if (event.name === 'runtime.nativeResponse') {
                                callback(event.message);
                                safari.self.removeEventListener('message', responseHandler);
                            }
                        };
                        safari.self.addEventListener('message', responseHandler);
                    }
                }
            };
        }
        
        // Content script communication
        if (window.top === window) {
            // Main frame
            safari.self.addEventListener('message', function(event) {
                if (event.name === 'wblock.executeScript') {
                    try {
                        const result = eval(event.message.code);
                        safari.extension.dispatchMessage('wblock.scriptResult', {
                            result: result,
                            id: event.message.id
                        });
                    } catch (error) {
                        safari.extension.dispatchMessage('wblock.scriptError', {
                            error: error.toString(),
                            id: event.message.id
                        });
                    }
                }
            });
        }
        """
    }
    
    /// Generate manifest.json for Safari Web Extension
    static func generateManifest() -> [String: Any] {
        return [
            "manifest_version": 2,
            "name": "wBlock Scripts",
            "version": "0.2.0",
            "description": "Advanced ad blocking scripts for wBlock",
            
            "permissions": [
                "webRequest",
                "webRequestBlocking",
                "tabs",
                "storage",
                "<all_urls>"
            ],
            
            "background": [
                "scripts": ["polyfill.js", "background.js"],
                "persistent": true
            ],
            
            "content_scripts": [
                [
                    "matches": ["*://*.youtube.com/*", "*://*.youtu.be/*"],
                    "js": ["polyfill.js", "youtube-detector.js"],
                    "run_at": "document_start",
                    "all_frames": false
                ]
            ],
            
            "web_accessible_resources": [
                "youtube-adblock.js",
                "youtube-adblock.css"
            ]
        ]
    }
    
    /// Generate YouTube detector script
    static func generateYouTubeDetector() -> String {
        return """
        // YouTube page detector
        (function() {
            'use strict';
            
            // Notify background script that we're on YouTube
            browser.runtime.sendMessage({
                type: 'youtubeDetected'
            });
            
            // Listen for navigation changes (YouTube is a SPA)
            let lastUrl = location.href;
            new MutationObserver(() => {
                const url = location.href;
                if (url !== lastUrl) {
                    lastUrl = url;
                    browser.runtime.sendMessage({
                        type: 'youtubeNavigated',
                        url: url
                    });
                }
            }).observe(document, {subtree: true, childList: true});
            
            // Listen for ad detection
            window.addEventListener('wblockAdBlocked', function(event) {
                browser.runtime.sendMessage({
                    type: 'adBlocked',
                    data: event.detail
                });
            });
            
            console.log('[wBlock] YouTube detector loaded');
        })();
        """
    }
}
