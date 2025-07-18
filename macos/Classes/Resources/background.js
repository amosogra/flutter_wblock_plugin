// Background script for wBlock Safari Extension
// Handles communication between content scripts and native extension

// Track active YouTube tabs
const youtubeTabs = new Map();

// Listen for messages from content scripts
browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log("[wBlock Background] Received message:", request.type);

  switch (request.type) {
    case "youtubeDetected":
      handleYouTubeDetected(sender.tab);
      break;

    case "adBlocked":
      handleAdBlocked(request.data, sender.tab);
      break;

    case "getSettings":
      getSettings().then(sendResponse);
      return true; // Will respond asynchronously

    case "injectScript":
      injectYouTubeScript(sender.tab.id);
      break;
  }
});

// Handle YouTube page detection
function handleYouTubeDetected(tab) {
  if (!youtubeTabs.has(tab.id)) {
    youtubeTabs.set(tab.id, {
      url: tab.url,
      adsBlocked: 0,
      startTime: Date.now(),
    });

    // Inject YouTube ad blocking script
    injectYouTubeScript(tab.id);
  }
}

// Handle ad blocked notification
function handleAdBlocked(data, tab) {
  if (youtubeTabs.has(tab.id)) {
    const tabData = youtubeTabs.get(tab.id);
    tabData.adsBlocked++;

    // Update badge
    browser.browserAction.setBadgeText({
      text: tabData.adsBlocked.toString(),
      tabId: tab.id,
    });

    // Log to native extension
    browser.runtime.sendNativeMessage("syferlab.wBlock", {
      action: "reportBlockedAd",
      url: data.url,
      type: data.type,
    });
  }
}

// Get settings from native extension
async function getSettings() {
  return new Promise((resolve) => {
    browser.runtime.sendNativeMessage(
      "syferlab.wBlock",
      {
        action: "getSettings",
      },
      (response) => {
        resolve(response || {});
      }
    );
  });
}

// Inject YouTube ad blocking script
function injectYouTubeScript(tabId) {
  browser.tabs.executeScript(
    tabId,
    {
      file: "youtube-adblock.js",
      runAt: "document_start",
      allFrames: false,
    },
    () => {
      console.log("[wBlock Background] Injected YouTube ad blocking script");
    }
  );

  // Also inject CSS
  browser.tabs.insertCSS(tabId, {
    file: "youtube-adblock.css",
    runAt: "document_start",
  });
}

// Clean up when tab is closed
browser.tabs.onRemoved.addListener((tabId) => {
  youtubeTabs.delete(tabId);
});

// Monitor tab updates
browser.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.url && youtubeTabs.has(tabId)) {
    // URL changed, might need to reinject scripts
    if (isYouTubeUrl(changeInfo.url)) {
      injectYouTubeScript(tabId);
    } else {
      // No longer on YouTube
      youtubeTabs.delete(tabId);
      browser.browserAction.setBadgeText({
        text: "",
        tabId: tabId,
      });
    }
  }
});

// Check if URL is YouTube
function isYouTubeUrl(url) {
  return (
    url.includes("youtube.com") ||
    url.includes("youtu.be") ||
    url.includes("youtube-nocookie.com")
  );
}

// Initialize extension
browser.runtime.onInstalled.addListener(() => {
  console.log("[wBlock Background] Extension installed/updated");

  // Set up declarative content rules for page action
  browser.declarativeContent.onPageChanged.removeRules(undefined, () => {
    browser.declarativeContent.onPageChanged.addRules([
      {
        conditions: [
          new browser.declarativeContent.PageStateMatcher({
            pageUrl: { hostSuffix: "youtube.com" },
          }),
          new browser.declarativeContent.PageStateMatcher({
            pageUrl: { hostSuffix: "youtu.be" },
          }),
        ],
        actions: [new browser.declarativeContent.ShowPageAction()],
      },
    ]);
  });
});

// Handle extension icon click
browser.browserAction.onClicked.addListener((tab) => {
  // Open wBlock app
  browser.runtime.sendNativeMessage("syferlab.wBlock", {
    action: "openApp",
  });
});

console.log("[wBlock Background] Background script loaded");
