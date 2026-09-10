const { app, BrowserWindow, Menu, screen, shell, nativeTheme } = require('electron');
const path = require('path');
const fs = require('fs');

const MIN_W = 640;
const MIN_H = 400;
const DEFAULT = { w: 960, h: 500, x: 80, y: 50 };
const BOUNDS_FILE = 'window-bounds.json';

function boundsPath() {
  return path.join(app.getPath('userData'), BOUNDS_FILE);
}

function loadBounds() {
  try {
    const b = JSON.parse(fs.readFileSync(boundsPath(), 'utf8').trim());
    const w = Math.max(MIN_W, parseInt(b.w, 10) || DEFAULT.w);
    const h = Math.max(MIN_H, parseInt(b.h, 10) || DEFAULT.h);
    let x = parseInt(b.x, 10);
    let y = parseInt(b.y, 10);
    if (Number.isNaN(x)) x = DEFAULT.x;
    if (Number.isNaN(y)) y = DEFAULT.y;
    return { width: w, height: h, x, y };
  } catch {
    return { width: DEFAULT.w, height: DEFAULT.h, x: DEFAULT.x, y: DEFAULT.y };
  }
}

function clampToWorkArea(bounds) {
  const display = screen.getDisplayMatching(bounds);
  const { workArea: wa } = display;
  let { width, height, x, y } = bounds;
  if (width > wa.width * 0.96 || height > wa.height * 0.96) {
    return {
      width: DEFAULT.w,
      height: DEFAULT.h,
      x: wa.x + 80,
      y: wa.y + 50,
    };
  }
  width = Math.min(width, wa.width - 20);
  height = Math.min(height, wa.height - 20);
  x = Math.max(wa.x, Math.min(x, wa.x + wa.width - width));
  y = Math.max(wa.y, Math.min(y, wa.y + wa.height - height));
  return { width, height, x, y };
}

function saveBounds(win) {
  if (!win || win.isDestroyed()) return;
  try {
    const b = win.getBounds();
    const dir = app.getPath('userData');
    fs.mkdirSync(dir, { recursive: true });
    const file = boundsPath();
    const tmp = file + '.tmp';
    fs.writeFileSync(tmp, JSON.stringify({ w: b.width, h: b.height, x: b.x, y: b.y }));
    fs.renameSync(tmp, file);
  } catch {
    /* ignore */
  }
}

function attachContextMenu(win) {
  win.webContents.on('context-menu', (_event, params) => {
    const { isEditable, selectionText, editFlags } = params;
    const hasSelection = Boolean(selectionText);
    if (!isEditable && !hasSelection) return;

    const template = isEditable
      ? [
          { role: 'undo', enabled: editFlags.canUndo },
          { role: 'redo', enabled: editFlags.canRedo },
          { type: 'separator' },
          { role: 'cut', enabled: editFlags.canCut },
          { role: 'copy', enabled: editFlags.canCopy },
          { role: 'paste', enabled: editFlags.canPaste },
          { role: 'selectAll', enabled: editFlags.canSelectAll },
        ]
      : [
          { role: 'copy', enabled: editFlags.canCopy },
          { role: 'selectAll', enabled: editFlags.canSelectAll },
        ];

    Menu.buildFromTemplate(template).popup({ window: win });
  });
}

function attachExternalLinkHandler(win) {
  const openExternal = (url) => {
    if (/^https?:/i.test(url)) shell.openExternal(url);
  };
  win.webContents.setWindowOpenHandler(({ url }) => {
    openExternal(url);
    return { action: 'deny' };
  });
  win.webContents.on('will-navigate', (event, url) => {
    if (url.startsWith('file:')) return;
    event.preventDefault();
    openExternal(url);
  });
}

function createWindow() {
  const win = new BrowserWindow({
    ...clampToWorkArea(loadBounds()),
    minWidth: MIN_W,
    minHeight: MIN_H,
    show: false,
    autoHideMenuBar: true,
    title: 'ResumePad',
    backgroundColor: nativeTheme.shouldUseDarkColors ? '#0d1117' : '#fafafa',
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });

  attachExternalLinkHandler(win);
  attachContextMenu(win);
  win.webContents.on('dom-ready', () => {
    win.webContents
      .executeJavaScript('document.documentElement.dataset.theme')
      .then((theme) => {
        if (!win.isDestroyed()) {
          win.setBackgroundColor(theme === 'dark' ? '#0d1117' : '#fafafa');
        }
      })
      .catch(() => {});
  });
  win.once('ready-to-show', () => win.show());
  win.loadFile(path.join(__dirname, '..', 'index.html'), { query: { standalone: '1' } });

  let saveTimer;
  const scheduleSave = () => {
    clearTimeout(saveTimer);
    saveTimer = setTimeout(() => saveBounds(win), 200);
  };
  win.on('resize', scheduleSave);
  win.on('move', scheduleSave);
  win.on('close', () => saveBounds(win));

  return win;
}

const gotLock = app.requestSingleInstanceLock();
if (!gotLock) {
  app.quit();
} else {
  app.on('second-instance', () => {
    const w = BrowserWindow.getAllWindows()[0];
    if (w) {
      if (w.isMinimized()) w.restore();
      w.focus();
    }
  });

  app.whenReady().then(() => {
    if (process.platform === 'win32') {
      app.setAppUserModelId('app.resumepad.desktop');
    }
    createWindow();
    app.on('activate', () => {
      if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
  });

  app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') app.quit();
  });
}
