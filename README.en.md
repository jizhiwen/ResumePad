# ResumePad

English · [中文](README.md)

A lightweight tool for capturing context when you switch tasks. Before you get interrupted or move on, write down the goal, progress, and next step; when you return, pick a task from the list on the left and resume within minutes.

**Install only via [Electron packages](https://github.com/jizhiwen/ResumePad/releases)** (Ubuntu / Windows / macOS). Opening `index.html` in a browser or double-clicking it is not supported; there is no script-based shortcut install.

![ResumePad screenshot](docs/screenshot-20260518-204754.png)

> This repository was developed with assistance from [Cursor](https://cursor.com).

## Install

Download the package for your OS from GitHub **Releases** (CI builds and publishes when you push a `v*` tag).

| Platform | Recommended | Alternative |
|----------|-------------|-------------|
| **Ubuntu** | `ResumePad-*-linux-x64.AppImage` (portable; `chmod +x` then run) | `ResumePad-*-linux-x64.deb` (`sudo apt install ./ResumePad-*.deb`) |
| **Windows** | `ResumePad-Setup-*-x64.exe` (installer) | `ResumePad-Portable-*-x64.exe` (portable) |
| **macOS (Apple Silicon)** | `ResumePad-*-mac-arm64.dmg` | `ResumePad-*-mac-arm64.zip` (unzip and drag `.app` to Applications) |
| **macOS (Intel)** | `ResumePad-*-mac-x64.dmg` | `ResumePad-*-mac-x64.zip` |

**Ubuntu AppImage:** If it will not start, install FUSE: `sudo apt install libfuse2` (22.04) or `libfuse3` (24.04+).

**macOS:** CI builds are not notarized. If Gatekeeper blocks the app, use **right-click → Open**, or allow it under **System Settings → Privacy & Security**.

After install, launch **ResumePad** from the app menu, Launchpad, or Start menu.

## Quick start

1. Install and open ResumePad.
2. **(Optional)** **Import** from the top bar → choose [`docs/dummy.json`](docs/dummy.json) for sample data.
3. When switching tasks, click **Switch** (or press `N`), save, then restore context from **Queued** on the left. On the preview page, use **Edit** or double-click a section to change content.

## Data storage

- Task data is stored locally in **IndexedDB** (`resumepad_db`); nothing is uploaded to a server.
- Export JSON backups regularly; always export before reinstalling or moving to another machine.

### User data directory

| Platform | Path |
|----------|------|
| Linux | `~/.config/resumepad/` |
| Windows | `%APPDATA%\resumepad\` |
| macOS | `~/Library/Application Support/resumepad/` |

**When created:** On first launch of the Electron app. The path is Electron’s standard `app.getPath('userData')` (matches the `name` field in `package.json`: `resumepad`). The whole directory is the Chromium user profile root.

```
~/.config/resumepad/          # Linux
├── window-bounds.json
├── Default/
│   ├── IndexedDB/          # tasks: resumepad_db
│   └── Local Storage/
├── Cache/
└── …
```

| Path / file | When written | Purpose |
|-------------|--------------|---------|
| `Default/IndexedDB/` | After first task/settings read or write | Queued tasks, completed history, settings |
| `Default/Local Storage/` | After first launch | `resumepad_theme`, `resumepad_sidebar_width` |
| `window-bounds.json` | After first resize or window close | e.g. `{"w":960,"h":500,"x":80,"y":50}` |

If you previously used an old Edge script install, **manually remove** it before switching to Electron:

```bash
rm -f ~/.local/bin/resumepad ~/.local/share/applications/resumepad.desktop
rm -rf ~/.local/opt/resumepad
rm -rf ~/.config/resumepad/app-root ~/.config/resumepad/edge-profile
```

Then install the AppImage or `.deb` from [Releases](https://github.com/jizhiwen/ResumePad/releases).

Uninstalling the Electron app does not delete `~/.config/resumepad/`; export JSON before clearing data.

## UI overview

| Area / control | Purpose |
|----------------|---------|
| **Queued** | Active tasks, sorted by queue time; click to open details |
| **Completed** | Finished tasks (kept until you delete them) |
| **Switch** | New task form (saved tasks join the queue) |
| **Settings** | UI language (中文 / English), theme (light/dark), summary copy fields (language and summary travel with JSON export/import; theme stays local) |
| **Edit** | Enter edit mode from the preview footer (same as double-clicking a section) |
| **Agent** | Copy a resume prompt for AI assistants |
| **Summary** | Copy a Markdown task summary per settings |
| **Done** | Move the current task to Completed |
| **Export / Import** | JSON backup and restore (merge or replace) |
| **Settings · appearance** | Light / dark theme (`T` still toggles theme) |

Each active task includes these fields so you know what to read first and what to do next:

- **Goal** — objective and definition of done  
- **Software requirements (SRS)** — scope, acceptance criteria, constraints (for humans and agents; included in Summary / Agent copy)  
- **Progress** — what is done and what you learned  
- **Next · do now** — the first action when you resume  
- **References** — paths, branches, URLs, commands  
- **Blockers** — open issues and blockers  
- **Notes** — anything else to remember  
- **Retrospective** — what went well, improvements, lessons (included in Summary / Agent copy)  
- **Attachments** — upload `.html` / `.htm` / `.md`; click to preview in a dialog; **Download** from the list or preview  

The preview **always shows** these sections; empty ones show gray placeholders. Rich text supports paste and drag-in images; **double-click an image** to zoom; in the lightbox use **Ctrl+scroll** to zoom and **drag** to pan; URLs become clickable links while editing. Attachment preview renders HTML in a sandboxed iframe and Markdown as a readable page.

## Sample data

The repo includes [`docs/dummy.json`](docs/dummy.json) (`version: 3`) with SRS, retrospective, and attachment examples. **Import:** top bar **Import** → choose file → **Merge** or **Replace**.

## Keyboard shortcuts

| Key | Action |
|-----|--------|
| `N` | Switch (new task form) |
| `T` | Toggle light / dark theme |
| `Enter` | Save while editing |
| `Alt+Enter` | New line while editing |
| `Tab` / `Shift+Tab` | Next / previous field while editing |
| `Esc` | Close image preview, or cancel edit and return to browse |
| `Ctrl` + scroll | Zoom in image preview |
| Drag | Pan in image preview |

## Releasing (maintainers)

Push a tag matching `v*`; GitHub Actions builds on Ubuntu, Windows, and macOS and creates a Release:

```bash
git tag v1.0.14
git push origin v1.0.14
```

Artifacts: `ResumePad-*-linux-x64.AppImage`, `.deb`, `ResumePad-Setup-*-x64.exe`, `ResumePad-Portable-*-x64.exe`, `ResumePad-*-mac-arm64.dmg`, `.zip` (and `mac-x64` for Intel Macs; hyphenated names, no spaces).

## Build from source (developers)

| Requirement | Notes |
|-------------|-------|
| Node.js | **18+** (20 recommended; see `.nvmrc`) |
| Linux extras | `librsvg2-bin` (icons), `libfuse2` (AppImage on Ubuntu 22.04) |

```bash
nvm use 20
./scripts/build-electron.sh linux   # runs npm ci and Node version check
./scripts/build-electron.sh win     # Windows only (prefer windows-latest CI)
./scripts/build-electron.sh mac     # macOS only (requires Mac or macos-latest CI)
npm start                           # dev mode
```

Output is in `dist/`.

## Project layout

```
ResumePad/
├── .github/workflows/release.yml   # tag-triggered Release
├── electron/main.js                # Electron main process
├── package.json                    # build config
├── index.html                      # UI and logic (single file)
├── scripts/build-electron.sh       # local build script
├── scripts/electron-icons.sh
├── icons/
├── docs/                           # screenshots, sample data
│   └── dummy.json
├── README.en.md
└── README.md
```

## TODO

- [ ] **macOS code signing and notarization** — CI builds are currently unsigned and not notarized; users may need **right-click → Open** on first launch. Later steps could include:
  - Apple Developer certificate (`.p12`) and GitHub Actions secrets: `CSC_LINK` (Base64 cert), `CSC_KEY_PASSWORD`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID`
  - Remove `CSC_IDENTITY_AUTO_DISCOVERY: false` in `release.yml` `build-macos`, enable `electron-builder` signing and notarization (`afterSign` or `electron-builder-notarize`)
  - Verify Gatekeeper allows opening without extra security prompts

## License and disclaimer

Personal tool, provided as-is. You are responsible for your data and backups.
