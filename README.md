# flirt-ios

Flirt iOS app — tone-based AI reply suggestions. SwiftUI, iOS 17+.
Phase 1 (app only); the custom keyboard extension arrives in v0.2.

Specs live in `flirt-docs` (ARCHITECTURE.md, IOS_KEYBOARD_RULES.md, ROADMAP.md).

## Setup

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen        # once
xcodegen generate            # after any project.yml change
open Flirt.xcodeproj
```

Run on an iPhone simulator. The app talks to the local backend at
`http://localhost:3000` — start it first:

```bash
cd ../Flirt-infra && ./scripts/up.sh
```

## Structure

```text
Flirt/
├── FlirtApp.swift
├── Config/AppConfig.swift          # API base URL
├── Models/Models.swift             # Tone, Suggestion, API DTOs
├── Networking/
│   ├── APIClient.swift             # actor — transparent device auth, 401 retry
│   └── KeychainHelper.swift        # tokens in Keychain
├── ViewModels/ReplyGeneratorViewModel.swift
└── Views/
    ├── ReplyGeneratorView.swift    # paste → tone → generate
    └── SuggestionCard.swift        # copy / edit inline / refine menu
```

## Features (Phase 1)

- Paste or type the received message
- 5 tones: ✨ Light Flirt · 🔥 Deep Flirt · 😂 Funny · 💪 Confident · 💼 Professional
- 3 AI suggestions per generation (real provider via the backend)
- Per suggestion: copy (with feedback), inline edit, refine (Shorter / Funnier / More Direct)
- Anonymous device auth handled automatically (Keychain-stored JWT)

## Next (v0.2)

Custom Keyboard Extension + App Groups — see `flirt-docs/IOS_KEYBOARD_RULES.md`
before starting: Full Access, memory limits, and physical-device testing rules.
