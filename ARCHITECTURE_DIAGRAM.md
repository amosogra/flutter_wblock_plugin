# Safari Ad Blocker Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP (UI)                             │
│  ┌─────────────────┐  ┌──────────────────┐  ┌──────────────────┐   │
│  │ Filter Manager  │  │ Stats Display    │  │ Settings Screen  │   │
│  └────────┬────────┘  └──────────────────┘  └──────────────────┘   │
└───────────┼─────────────────────────────────────────────────────────┘
            │ Method Channel
            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    NATIVE SWIFT LAYER                                │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │               FlutterWblockPlugin.swift                      │   │
│  │  • loadFilterLists()    • applyChanges()                   │   │
│  │  • getFilterStats()     • updateFilters()                  │   │
│  └────────┬──────────────────────┬─────────────────────────────┘   │
│           │                      │                                   │
│           ▼                      ▼                                   │
│  ┌────────────────────┐  ┌────────────────────────────────────┐    │
│  │  FilterManager     │  │  ContentBlockerManager             │    │
│  │  • Download lists  │  │  • Convert AdBlock → Safari rules │    │
│  │  • Store locally   │  │  • Distribute to extensions       │    │
│  └───────────┬────────┘  └────────┬───────────────────────────┘    │
└──────────────┼────────────────────┼─────────────────────────────────┘
               │                    │
               ▼                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    SHARED CONTAINER                                  │
│                  (group.syferlab.wBlock)                            │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Network Rules         │  Script Data         │  Resources   │   │
│  │  • blockerList.json    │  • general_scriptlets.json         │   │
│  │  • blockerList2.json   │  • youtube_scriptlets.json         │   │
│  │                        │  • youtube-adblock.js/.css         │   │
│  └─────────────────────────────────────────────────────────────┘   │
└───────────┬────────────────────────┬───────────────────────────────┘
            │                        │
            ▼                        ▼
┌───────────────────────┐  ┌─────────────────────────────────────────┐
│  CONTENT BLOCKERS     │  │      SAFARI WEB EXTENSION               │
│                       │  │        (wBlock-Scripts)                 │
│  ┌─────────────────┐  │  │  ┌─────────────────────────────────┐   │
│  │ wBlock-Filters  │  │  │  │  background.js                  │   │
│  │ • Network block │  │  │  │  • Handle messages              │   │
│  └─────────────────┘  │  │  │  • Load scriptlets              │   │
│                       │  │  │  • Communicate with native      │   │
│  ┌─────────────────┐  │  │  └──────────┬──────────────────────┘   │
│  │ wBlock-Advance  │  │  │             │                           │
│  │ • Advanced rules│  │  │             ▼                           │
│  │ • YouTube CSS   │  │  │  ┌─────────────────────────────────┐   │
│  └─────────────────┘  │  │  │  content.js                     │   │
│                       │  │  │  • Detect YouTube pages         │   │
└───────────────────────┘  │  │  • Request blocking data        │   │
                           │  │  • Inject scriptlets & CSS      │   │
                           │  └─────────────────────────────────┘   │
                           └─────────────────────────────────────────┘
                                            │
                                            ▼
                           ┌─────────────────────────────────────────┐
                           │         YOUTUBE.COM PAGE                 │
                           │  • Ads blocked at network level         │
                           │  • Ad elements hidden by CSS            │
                           │  • Ad scripts intercepted by scriptlets │
                           └─────────────────────────────────────────┘
```

## Message Flow for YouTube Ad Blocking

```
YouTube Page Load
      │
      ▼
content.js: "Hey, I'm on YouTube!"
      │
      ├─> browser.runtime.sendMessage({
      │     action: "getAdvancedBlockingData",
      │     url: "https://youtube.com/watch?v=..."
      │   })
      │
      ▼
background.js: "Let me get that data for you"
      │
      ├─> browser.runtime.sendNativeMessage(NATIVE_APP_ID, message)
      │
      ▼
SafariExtensionHandler.swift: "Here's YouTube blocking data"
      │
      ├─> Returns: {
      │     scriptlets: [...],
      │     cssInject: [...],
      │     scripts: [...],
      │     cssExtended: [...]
      │   }
      │
      ▼
background.js: "Let me load the actual scriptlet code"
      │
      ├─> fetch("/web_accessible_resources/scriptlets/json-prune.js")
      ├─> fetch("/web_accessible_resources/scriptlets/set-constant.js")
      └─> etc...
      │
      ▼
content.js: "Got it! Injecting everything now"
      │
      ├─> Inject CSS to hide ads
      ├─> Execute scriptlets to modify JS behavior
      └─> Inject scripts to intercept player
      │
      ▼
YouTube Page: "Where did all the ads go? 🎉"
```
