import Foundation

class YouTubeAdBlockHandler {
    
    static func generateYouTubeNetworkRules() -> [[String: Any]] {
        // Network rules to block YouTube ads
        let adDomains = [
            "doubleclick.net",
            "googleadservices.com",
            "googlesyndication.com",
            "google-analytics.com",
            "googletagmanager.com",
            "googletagservices.com",
            "youtube.com/api/stats/ads",
            "youtube.com/api/stats/qoe",
            "youtube.com/pagead",
            "youtube.com/ptracking",
            "youtube.com/get_midroll_info"
        ]
        
        var rules: [[String: Any]] = []
        
        // Ensure YouTube domains are lowercase
        let youtubeDomains = ["youtube.com", "youtube-nocookie.com", "youtu.be"].map { $0.lowercased() }
        let allYoutubeDomains = ["youtube.com", "youtube-nocookie.com", "youtu.be", "googlevideo.com"].map { $0.lowercased() }
        
        // Block ad domains on YouTube
        for domain in adDomains {
            rules.append([
                "trigger": [
                    "url-filter": ".*\(domain.replacingOccurrences(of: ".", with: "\\\\."))",
                    "if-domain": youtubeDomains
                ],
                "action": ["type": "block"]
            ])
        }
        
        // Block specific YouTube ad patterns
        let adPatterns = [
            ".*\\\\/pagead\\\\/",
            ".*\\\\/get_video_info.*adformat",
            ".*\\\\/stats\\\\/ads",
            ".*\\\\/api\\\\/stats\\\\/qoe.*adformat",
            ".*youtube\\\\.com.*\\\\/ad_companion",
            ".*youtube\\\\.com.*\\\\/generate_204",
            ".*youtube\\\\.com.*\\\\/get_midroll_",
            ".*youtube\\\\.com\\\\/api\\\\/stats\\\\/playback.*ad",
            ".*googlevideo\\\\.com\\\\/videoplayback.*ctier=L",
            ".*youtube\\\\.com\\\\/youtubei\\\\/v1\\\\/player\\\\/ad_break",
            ".*\\\\/youtubei\\\\/v1\\\\/log_event.*adformat"
        ]
        
        for pattern in adPatterns {
            rules.append([
                "trigger": [
                    "url-filter": pattern,
                    "if-domain": allYoutubeDomains
                ],
                "action": ["type": "block"]
            ])
        }
        
        return rules
    }
    
    static func generateYouTubeAdBlockScript() -> String {
        return """
        // YouTube Ad Blocking Script
        (function() {
            'use strict';
            
            // Block YouTube ads by intercepting player configuration
            const origParse = JSON.parse;
            JSON.parse = function(text) {
                const obj = origParse.apply(this, arguments);
                
                // Remove ads from player response
                if (obj && obj.playerResponse) {
                    delete obj.playerResponse.adPlacements;
                    delete obj.playerResponse.playerAds;
                    if (obj.playerResponse.adSlots) {
                        delete obj.playerResponse.adSlots;
                    }
                }
                
                // Remove ads from initial data
                if (obj && obj.contents && obj.contents.twoColumnWatchNextResults) {
                    const results = obj.contents.twoColumnWatchNextResults;
                    if (results.results && results.results.results) {
                        results.results.results.contents = results.results.results.contents.filter(item => {
                            return !item.promotedSparklesWebRenderer && 
                                   !item.promotedVideoRenderer &&
                                   !item.compactPromotedVideoRenderer;
                        });
                    }
                }
                
                return obj;
            };
            
            // Block ad requests
            const origFetch = window.fetch;
            window.fetch = function(...args) {
                const url = args[0];
                if (typeof url === 'string') {
                    if (url.includes('/pagead/') || 
                        url.includes('/get_video_info') && url.includes('adformat') ||
                        url.includes('/stats/ads') ||
                        url.includes('/youtubei/v1/player/ad_break') ||
                        url.includes('/youtubei/v1/log_event') && url.includes('adformat')) {
                        return Promise.reject(new Error('Blocked'));
                    }
                }
                return origFetch.apply(this, arguments);
            };
            
            // Block XHR ad requests
            const origOpen = XMLHttpRequest.prototype.open;
            XMLHttpRequest.prototype.open = function(method, url) {
                if (typeof url === 'string') {
                    if (url.includes('/pagead/') || 
                        url.includes('/get_video_info') && url.includes('adformat') ||
                        url.includes('/stats/ads') ||
                        url.includes('/youtubei/v1/player/ad_break')) {
                        throw new Error('Blocked');
                    }
                }
                return origOpen.apply(this, arguments);
            };
            
            // Remove ad containers when they appear
            const adSelectors = [
                '.video-ads',
                '.ytp-ad-module',
                '.ytp-ad-player-overlay',
                '#player-ads',
                '.ytp-ad-overlay-container',
                '.ytp-ad-message-container',
                '.ytp-ad-overlay-slot',
                'ytd-promoted-video-renderer',
                'ytd-display-ad-renderer',
                'ytd-promoted-sparkles-web-renderer',
                'ytd-rich-item-renderer:has(ytd-display-ad-renderer)',
                'ytd-ad-slot-renderer',
                'ytm-promoted-video-renderer',
                'ytd-companion-slot-renderer',
                'ytd-action-companion-ad-renderer',
                'ytd-banner-promo-renderer',
                'ytd-video-masthead-ad-v3-renderer',
                'ytd-primetime-promo-renderer'
            ];
            
            // Skip ads automatically
            let adSkipInterval;
            function skipAds() {
                // Skip video ads
                const skipButton = document.querySelector('.ytp-ad-skip-button, .ytp-ad-skip-button-modern');
                if (skipButton) {
                    skipButton.click();
                }
                
                // Skip overlay ads
                const overlayClose = document.querySelector('.ytp-ad-overlay-close-button');
                if (overlayClose) {
                    overlayClose.click();
                }
                
                // Remove ad elements
                adSelectors.forEach(selector => {
                    const elements = document.querySelectorAll(selector);
                    elements.forEach(el => el.remove());
                });
                
                // Force player to play if paused by ad
                const video = document.querySelector('video');
                const adShowing = document.querySelector('.ad-showing');
                if (video && adShowing) {
                    video.currentTime = video.duration || 0;
                    video.play();
                }
            }
            
            // Start monitoring for ads
            if (window.location.hostname.includes('youtube')) {
                adSkipInterval = setInterval(skipAds, 100);
                
                // Clean up on navigation
                window.addEventListener('yt-navigate-finish', () => {
                    clearInterval(adSkipInterval);
                    adSkipInterval = setInterval(skipAds, 100);
                });
            }
            
            // Prevent ad tracking
            Object.defineProperty(navigator, 'sendBeacon', {
                value: function() { return true; }
            });
            
        })();
        """
    }
    
    static func generateYouTubeAdBlockCSS() -> String {
        return """
        /* YouTube Ad Blocking CSS */
        
        /* Hide video ads */
        .video-ads,
        .ytp-ad-module,
        .ytp-ad-player-overlay,
        .ytp-ad-overlay-container,
        .ytp-ad-message-container,
        .ytp-ad-overlay-slot,
        .ytp-ad-overlay-close-button,
        .ytp-ad-overlay-image,
        .ytp-ad-text-overlay,
        .ytp-ad-preview-container,
        .ytp-ad-progress-list {
            display: none !important;
        }
        
        /* Hide promoted content */
        ytd-promoted-video-renderer,
        ytd-display-ad-renderer,
        ytd-promoted-sparkles-web-renderer,
        ytd-rich-item-renderer:has(ytd-display-ad-renderer),
        ytd-ad-slot-renderer,
        ytm-promoted-video-renderer,
        ytd-companion-slot-renderer,
        ytd-action-companion-ad-renderer,
        ytd-engagement-panel-section-list-renderer[target-id="engagement-panel-ads"],
        #masthead-ad,
        #player-ads {
            display: none !important;
        }
        
        /* Hide banner and promo */
        ytd-banner-promo-renderer,
        ytd-video-masthead-ad-v3-renderer,
        ytd-primetime-promo-renderer,
        tp-yt-paper-dialog:has(ytd-mealbar-promo-renderer),
        ytd-statement-banner-renderer,
        ytd-mealbar-promo-renderer {
            display: none !important;
        }
        
        /* Hide shorts ads */
        ytd-reel-video-renderer:has(ytd-ad-slot-renderer),
        ytm-reel-item-renderer:has(ytm-ad-slot-renderer) {
            display: none !important;
        }
        
        /* Hide playlist ads */
        ytd-playlist-panel-video-renderer:has([aria-label*="Ad"]) {
            display: none !important;
        }
        
        /* Hide ad badges */
        .ytp-ad-badge,
        .ytd-badge-supported-renderer:has-text("Ad"),
        .badge-style-type-ad {
            display: none !important;
        }
        
        /* Fix layout after removing ads */
        ytd-rich-grid-renderer #contents:has(ytd-display-ad-renderer) {
            margin-top: 0 !important;
        }
        
        /* Prevent ad placeholders */
        .ytp-ad-player-overlay-skip-or-preview,
        .ytp-ad-player-overlay-progress-bar,
        .ytp-ad-player-overlay-instream-info {
            display: none !important;
        }
        """
    }
    
    static func generateScriptletConfiguration() -> [String: Any] {
        // Configuration for scriptlet-based YouTube ad blocking
        return [
            "youtube": [
                [
                    "name": "json-prune",
                    "args": ["playerResponse.adPlacements", "playerResponse.playerAds", "adSlots"]
                ],
                [
                    "name": "set-constant",
                    "args": ["ytInitialPlayerResponse.adPlacements", "undefined"]
                ],
                [
                    "name": "set-constant", 
                    "args": ["ytInitialData.contents.twoColumnWatchNextResults.results.results.contents.[].promotedSparklesWebRenderer", "undefined"]
                ],
                [
                    "name": "abort-on-property-read",
                    "args": ["playerResponse.adPlacements"]
                ],
                [
                    "name": "abort-current-inline-script",
                    "args": ["playerResponse", "adPlacements"]
                ],
                [
                    "name": "remove-attr",
                    "args": ["id", "[id^=\"player-ads\"]"]
                ],
                [
                    "name": "remove-attr",
                    "args": ["id", "[id^=\"masthead-ad\"]"]
                ]
            ]
        ]
    }
}