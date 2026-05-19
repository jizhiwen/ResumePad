const fs = require('fs');
const path = require('path');

/** 移除旧版 Edge 安装留下的 app-root、edge-profile（不迁移数据）。 */
function removeLegacyEdgeLayout(userData) {
  for (const name of ['app-root', 'edge-profile']) {
    const target = path.join(userData, name);
    try {
      if (fs.existsSync(target)) {
        fs.rmSync(target, { recursive: true, force: true });
      }
    } catch {
      /* ignore */
    }
  }
}

module.exports = { removeLegacyEdgeLayout };
