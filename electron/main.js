const { app, BrowserWindow, screen } = require('electron');
const path = require('path');
const fs = require('fs');

const MIN_W = 640;
const MIN_H = 400;
const DEFAULT = { w: 960, h: 500, x: 80, y: 50 };

function boundsPath() {
  return path.join(app.getPath('userData'), 'window-bounds.json');
}

function loadBounds() {
  try {
    const raw = fs.readFileSync(boundsPath(), 'utf8').trim();
    const b = JSON.parse(raw);
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
  const wa = display.workArea;
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
    const data = { w: b.width, h: b.height, x: b.x, y: b.y };
    const tmp = boundsPath() + '.tmp';
    fs.writeFileSync(tmp, JSON.stringify(data));
    fs.renameSync(tmp, boundsPath());
  } catch {
    /* ignore */
  }
}

function indexHtmlPath() {
  return path.join(__dirname, '..', 'index.html');
}

function createWindow() {
  const bounds = clampToWorkArea(loadBounds());
  const win = new BrowserWindow({
    ...bounds,
    minWidth: MIN_W,
    minHeight: MIN_H,
    show: false,
    autoHideMenuBar: true,
    title: 'ResumePad',
    backgroundColor: '#fafafa',
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });

  win.once('ready-to-show', () => win.show());

  win.loadFile(indexHtmlPath(), { query: { standalone: '1' } });

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
