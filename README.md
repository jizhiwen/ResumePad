# ResumePad

任务切换时的上下文记录小工具。在被打断或换任务前，把「目标、进度、下一步」等写清楚；回来时从左侧列表点选，几分钟内接上上次的工作状态。

静态页面，**无需后端**。用 Edge 打开 `index.html` 即可；若希望 Dock/任务栏使用 **ResumePad 独立图标**（与 Edge 分开），可运行安装脚本。作者仅在 **Microsoft Edge** 上做过日常使用验证。

![ResumePad 界面示例](screenshot-20260518-204754.png)

> 本仓库代码由 [Cursor](https://cursor.com) 辅助生成。

## 快速开始

1. 克隆或下载本仓库。
2. 双击 `index.html`（或在 Edge 中打开本地路径）。
3. **（可选）** 顶部 **导入** → 选择 [`dummy.json`](dummy.json) 体验示例数据。
4. 需要切换任务时，点击 **Switch**（或 `N`），保存后可在左侧 **封存** 列表恢复上下文；预览页可 **编辑** 或双击区块修改。

## 独立图标（与 Edge 分开）

仅双击 `index.html` 时，Dock/任务栏会显示 **Edge** 图标。安装快捷方式后，用 **ResumePad 图标** 启动（独立窗口 + 独立图标）。

| 系统 | 安装 | 卸载 |
|------|------|------|
| **Linux** | `./install-desktop-entry.sh` | `./uninstall-desktop-entry.sh` |
| **Windows** | 双击 `install-desktop-entry.bat` | 双击 `uninstall-desktop-entry.bat` |

安装后：

- **Linux**：应用菜单搜索 **ResumePad** → 固定到 Dock；通过该图标启动。
- **Windows**：桌面或开始菜单 **ResumePad** 快捷方式；使用独立 Edge 配置目录（`%LOCALAPPDATA%\ResumePad\EdgeProfile`），任务栏与 Edge 分开。**请始终用快捷方式启动**，数据只在该配置中。

Linux 启动器会设置 `CHROME_DESKTOP=resumepad.desktop`、独立配置目录与 `--class=ResumePad`；Wayland 下默认用 X11 模式以便 Dock 正确分组。

**窗口大小**：通过启动器 / 快捷方式打开（`?standalone=1`）时，页面会记住上次关闭时的窗口大小（默认约 **960×500**），保存在该 Edge 配置的 `localStorage` 中。

**若仍与 Edge 图标合并：** 取消 Dock 旧固定 → 重新 `./install-desktop-entry.sh` → 只从应用菜单 **ResumePad** 启动并再固定。必要时用 `xprop WM_CLASS` 查看窗口类名，并改 `~/.local/share/applications/resumepad.desktop` 中的 `StartupWMClass=`。

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
├── index.html                      # 全部 UI 与逻辑（单文件）
├── launch-app.sh / launch-app.bat  # 启动器（安装脚本调用）
├── install-desktop-entry.sh        # Linux 安装菜单项 / Dock
├── uninstall-desktop-entry.sh      # Linux 卸载
├── install-desktop-entry.bat         # Windows 安装快捷方式
├── uninstall-desktop-entry.bat     # Windows 卸载
├── install-windows-shortcut.ps1    # Windows 安装（由 .bat 调用）
├── uninstall-windows-shortcut.ps1  # Windows 卸载（由 .bat 调用）
├── icons/                          # 图标（favicon / Dock / 快捷方式）
├── dummy.json                      # 示例导入数据
├── screenshot-20260518-204754.png
└── README.md
```

## 许可与说明

个人工具，按现状提供。数据安全与备份请自行负责。
