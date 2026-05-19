# ResumePad

任务切换时的上下文记录小工具。在被打断或换任务前，把「目标、进度、下一步」等写清楚；回来时从左侧列表点选，几分钟内接上上次的工作状态。

静态页面，**无需后端**。推荐安装 **Electron 桌面版**（Windows / Linux，自带 Chromium，类似 draw.io）；也可用 Edge 打开 `index.html` 或运行 Linux 安装脚本。

![ResumePad 界面示例](screenshot-20260518-204754.png)

> 本仓库代码由 [Cursor](https://cursor.com) 辅助生成。

## 快速开始

1. 克隆或下载本仓库。
2. 双击 `index.html`（或在 Edge 中打开本地路径）。
3. **（可选）** 顶部 **导入** → 选择 [`dummy.json`](dummy.json) 体验示例数据。
4. 需要切换任务时，点击 **Switch**（或 `N`），保存后可在左侧 **封存** 列表恢复上下文；预览页可 **编辑** 或双击区块修改。

## Electron 桌面版（推荐，Windows + Linux）

与 draw.io 一样打包 **Electron**，不依赖本机 Edge。

| 要求 | 说明 |
|------|------|
| Node.js | **18+**（仅构建时；Ubuntu 自带 `apt install nodejs` 多为 12，**不可用**） |
| npm | 与 Node 20 配套（见下方安装命令） |
| 图标工具 | `rsvg-convert` 或 ImageMagick（构建前生成 PNG） |

### 安装 Node 20（Ubuntu，构建前执行一次）

系统若已是 Node 12，安装 Electron 会报 `Unexpected token '?'`。请升级：

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
node -v    # 应显示 v20.x 或 v22.x
npm -v
```

然后删除旧依赖并重新构建：

```bash
cd ~/src/ResumePad
rm -rf node_modules package-lock.json
./scripts/build-electron.sh
```

### 构建安装包

```bash
cd ResumePad
./scripts/build-electron.sh          # Linux + Windows（当前系统能编的目标）
./scripts/build-electron.sh linux    # 仅 Linux（AppImage + .deb）
./scripts/build-electron.sh win      # 仅 Windows（在 Windows 或交叉环境）
```

产物在 `dist/`：

| 平台 | 文件 |
|------|------|
| **Linux** | `ResumePad-*-x86_64.AppImage`、`resumepad_*_amd64.deb` |
| **Windows** | `ResumePad Setup *.exe`（安装包）、`ResumePad * portable.exe` |

开发调试：

```bash
npm install
npm start
```

用户数据目录（任务 IndexedDB、窗口大小）：

| 平台 | 路径 |
|------|------|
| Linux | `~/.config/ResumePad/`（Electron 子目录） |
| Windows | `%APPDATA%\ResumePad\` |

窗口大小由 Electron 主进程写入 `window-bounds.json`，**无需 xwininfo**。

---

## Linux：Edge 应用模式（备选）

不构建 Electron 时，可用系统 **Edge** + 安装脚本（体积更小，依赖本机 Edge）。

| draw.io | ResumePad (Edge) |
|---------|------------------|
| `/opt/drawio/drawio` | `~/.local/opt/resumepad/resumepad` |
| 内置 Chromium | 本机 **Microsoft Edge** |
| 用户数据 | `~/.config/ResumePad/` |

### 安装 / 卸载

```bash
./install-desktop-entry.sh              # 默认装到 ~/.local/opt/resumepad
./install-desktop-entry.sh /opt/resumepad   # 系统级（需 sudo 写 /opt）
./uninstall-desktop-entry.sh
```

安装后会得到：

- 程序：`~/.local/opt/resumepad/resumepad`（与 `drawio` 同级入口）
- 命令：`resumepad`（`~/.local/bin` 符号链接）
- 菜单：`.desktop` 中 `Exec=…/resumepad`（**不再依赖 git 仓库路径**）
- 应用文件：`~/.local/opt/resumepad/app/`（`index.html`、图标等）

从应用菜单打开 **ResumePad** 即可；开发时仍可在仓库内执行 `./resumepad` 或 `./launch-app.sh`。

| 系统 | 安装 | 卸载 |
|------|------|------|
| **Linux** | `./install-desktop-entry.sh` | `./uninstall-desktop-entry.sh` |
| **Windows** | 双击 `install-desktop-entry.bat` | 双击 `uninstall-desktop-entry.bat` |

**配置目录**（`~/.config/ResumePad/`，安装时自动初始化）：`window-bounds.json`、`app-root` → 安装目录下的 `app/`、`edge-profile`（IndexedDB）。

**窗口大小**：需 `x11-utils`（`xwininfo`）；经 `resumepad` 启动后自动记录。

**Dock：** 取消旧固定项后，从菜单重新打开并固定 ResumePad。

## 界面说明

| 区域 / 按钮 | 作用 |
|-------------|------|
| **封存** | 进行中的任务，按封存时间排序；列表预览支持多行换行，富文本会转为纯文本显示；拖动列表与正文之间的分隔条可调整宽度（会记住） |
| **完成** | 已标记完成的任务（默认保留约 14 天） |
| **Switch** | 新建封存或切换编辑当前任务 |
| **设置** | 界面语言（中文 / English）、外观（浅色/深色）、配置「摘要」复制字段（语言与摘要随 JSON 导出/导入；主题存于本机） |
| **编辑** | 预览页底部进入编辑（与双击区块等效） |
| **Agent** | 一键复制面向 AI 助手的恢复提示词 |
| **摘要** | 按设置复制 Markdown 格式的任务摘要 |
| **完成** | 将当前封存移入完成历史 |
| **导出 / 导入** | JSON 备份与恢复（支持合并或覆盖） |
| **设置 · 外观** | 浅色 / 深色主题（快捷键 `T` 仍可切换） |

每条封存包含这些字段，便于「回来先读什么、立刻做什么」：

- **要达成什么** — 目标与成功标准  
- **做到哪了** — 已完成与刚试过的结论  
- **下一步 · 立刻做** — 恢复后第一件事  
- **关键引用** — 路径、分支、URL、命令等  
- **卡点 / 未决** — 阻塞与待决问题  
- **备忘** — 其他需要记住的信息  

预览页会**始终显示**上述区块；无内容时显示灰色占位提示（与编辑框 placeholder 一致）。富文本区域支持粘贴或拖入图片（会自动压缩后存入本地数据库）；编辑时 URL 可自动识别为可点击链接，保存仍以纯文本/HTML 安全字段入库。

## 示例数据

仓库提供 [`dummy.json`](dummy.json)，格式与 **导出** 一致（`version: 3`），包含：

- 3 条封存示例：完整字段、富文本/URL、极简仅标题与下一步  
- 2 条完成历史示例  
- `settings.summaryInclude` 示例（部分摘要字段默认不勾选）

**导入步骤：** 顶部 **导入** → 选择 `dummy.json` → **合并到现有**（保留你本机数据）或 **覆盖现有**（清空后仅保留示例）。导入后可在左侧列表与预览页逐项查看效果。

## 快捷键

| 按键 | 功能 |
|------|------|
| `N` | Switch（新建/切换任务表单） |
| `T` | 切换浅色 / 深色主题 |
| `Esc` | 在编辑表单中取消并返回浏览 |

## 数据存储

- 数据保存在浏览器 **IndexedDB**（`resumepad_db`），仅本机、仅当前浏览器配置，不会上传到任何服务器。
- 建议定期使用 **导出** 做 JSON 备份；换机或清缓存前务必先导出。
- 导出 JSON 包含 `version`、`tasks`、`history`、`settings`（`locale`、`summaryInclude` 等）。
- 若曾使用旧版 localStorage，首次打开会自动迁移到 IndexedDB。
- Windows 快捷方式：`%LOCALAPPDATA%\ResumePad\EdgeProfile`；Linux 启动器：`~/.config/ResumePad/edge-profile`。与直接双击 `index.html` 的 Edge **不共用**数据。

## 项目结构

```
ResumePad/
├── electron/main.js                # Electron 主进程
├── package.json                    # Electron 构建配置
├── index.html                      # 全部 UI 与逻辑（单文件）
├── resumepad                       # Edge 版入口（Linux 安装用）
├── lib/launch-app.sh               # Edge 应用模式
├── scripts/build-electron.sh       # 构建 AppImage / deb / exe
├── scripts/install-app.sh          # Edge 版安装到 ~/.local/opt/resumepad
├── install-desktop-entry.sh
├── uninstall-desktop-entry.sh
├── install-desktop-entry.bat         # Windows 安装快捷方式
├── uninstall-desktop-entry.bat     # Windows 卸载
├── install-windows-shortcut.ps1    # Windows 安装（由 .bat 调用）
├── uninstall-windows-shortcut.ps1  # Windows 卸载（由 .bat 调用）
├── icons/                          # 图标（PNG favicon / Dock / 快捷方式）
├── scripts/init-config.sh          # 初始化 ~/.config/ResumePad
├── scripts/setup-app-link.sh       # app-root 符号链接
├── scripts/bounds-wm.py              # 从 X11 读取窗口尺寸
├── scripts/window-bounds.py        # 默认配置与 window-bounds.json
├── manifest.webmanifest            # PWA 清单（应用图标元数据）
├── dummy.json                      # 示例导入数据
├── screenshot-20260518-204754.png
└── README.md
```

## 许可与说明

个人工具，按现状提供。数据安全与备份请自行负责。
