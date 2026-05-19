# ResumePad

任务切换时的上下文记录小工具。在被打断或换任务前，把「目标、进度、下一步」等写清楚；回来时从左侧列表点选，几分钟内接上上次的工作状态。

**仅支持通过 [Electron 安装包](https://github.com/jizhiwen/ResumePad/releases) 安装使用**（Ubuntu / Windows）。不支持双击 `index.html`、浏览器直接打开，也不提供脚本安装快捷方式。

![ResumePad 界面示例](docs/screenshot-20260518-204754.png)

> 本仓库代码由 [Cursor](https://cursor.com) 辅助生成。

## 安装

在 GitHub **Releases** 页面下载与系统匹配的安装包（推送 `v*` 标签后会由 CI 自动构建并发布）。

| 平台 | 推荐 | 备选 |
|------|------|------|
| **Ubuntu** | `ResumePad-*-linux-x64.AppImage`（免安装，`chmod +x` 后双击） | `ResumePad-*-linux-x64.deb`（`sudo apt install ./ResumePad-*.deb`） |
| **Windows** | `ResumePad-Setup-*-x64.exe`（安装包） | `ResumePad-Portable-*-x64.exe`（免安装） |

**Ubuntu AppImage 提示：** 若无法运行，可安装 FUSE：`sudo apt install libfuse2`（22.04）或 `libfuse3`（24.04+）。

安装后从应用菜单或开始菜单启动 **ResumePad**。

## 快速开始

1. 安装并打开 ResumePad。
2. **（可选）** 顶部 **导入** → 选择 [`dummy.json`](dummy.json) 体验示例数据。
3. 需要切换任务时，点击 **Switch**（或 `N`），保存后可在左侧 **封存** 列表恢复上下文；预览页可 **编辑** 或双击区块修改。

## 数据存储

- 任务数据保存在本机 **IndexedDB**（`resumepad_db`），不会上传到任何服务器。
- 建议定期 **导出** JSON 备份；换机或重装前务必先导出。
- 用户数据目录：

| 平台 | 路径 |
|------|------|
| Linux | `~/.config/ResumePad/` |
| Windows | `%APPDATA%\ResumePad\` |

窗口大小由 Electron 主进程写入 `window-bounds.json`。

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

预览页会**始终显示**上述区块；无内容时显示灰色占位提示。富文本区域支持粘贴或拖入图片；编辑时 URL 可自动识别为可点击链接。

## 示例数据

仓库提供 [`dummy.json`](dummy.json)（`version: 3`）。**导入：** 顶部 **导入** → 选择文件 → **合并到现有** 或 **覆盖现有**。

## 快捷键

| 按键 | 功能 |
|------|------|
| `N` | Switch（新建/切换任务表单） |
| `T` | 切换浅色 / 深色主题 |
| `Esc` | 在编辑表单中取消并返回浏览 |

## 发布新版本（维护者）

推送符合 `v*` 的 tag 后，GitHub Actions 会在 Ubuntu 与 Windows 上分别构建安装包，并创建 Release：

```bash
git tag v1.0.0
git push origin v1.0.0
```

产物：`ResumePad-*-linux-x64.AppImage`、`.deb`、`ResumePad-Setup-*-x64.exe`、`ResumePad-Portable-*-x64.exe`（文件名均为连字符，无空格）。

## 从源码构建（开发者）

| 要求 | 说明 |
|------|------|
| Node.js | **18+**（推荐 20，见 `.nvmrc`） |
| Linux 额外依赖 | `librsvg2-bin`（图标）、`libfuse2`（AppImage，Ubuntu 22.04） |

```bash
nvm use 20          # 或安装 Node 20 LTS
npm ci
./scripts/build-electron.sh linux   # 仅 Linux
./scripts/build-electron.sh win     # 仅 Windows（建议在 windows-latest 上构建）
npm start                           # 开发调试
```

产物在 `dist/`。

## 项目结构

```
ResumePad/
├── .github/workflows/release.yml   # tag 触发自动 Release
├── electron/main.js                # Electron 主进程
├── package.json                    # 构建配置
├── index.html                      # UI 与逻辑（单文件）
├── scripts/build-electron.sh       # 本地构建脚本
├── scripts/electron-icons.sh
├── icons/
├── docs/                           # 截图等文档资源
├── dummy.json
└── README.md
```

## 许可与说明

个人工具，按现状提供。数据安全与备份请自行负责。
