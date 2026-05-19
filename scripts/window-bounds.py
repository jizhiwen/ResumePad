#!/usr/bin/env python3
"""
ResumePad 窗口配置辅助脚本（可选，手动调试；正常由 Edge 自动记住窗口）。

子命令：
  init     首次安装/启动：创建目录与默认 window-bounds.json（不覆盖已有有效记录）。
  prepare  启动前：读 window-bounds.json，同步到 Edge Preferences。
  save     关闭后：从 X11 / Edge 读出窗口信息，写入 window-bounds.json。
  read     输出 JSON：{"w","h","x","y"}，供 launch-app 传入 --window-size/position。
  theme    输出 dark 或 light（空为未设置），供 launch-app 设置 --background-color。

用法：window-bounds.py <init|prepare|save|read|theme> <edge-profile-dir> [config-dir]
config-dir 默认为 ~/.config/ResumePad。
"""
import glob
import json
import os
import re
import subprocess
import sys
import time

DEFAULT = {'w': 960, 'h': 500, 'x': 80, 'y': 50}
MIN_W, MIN_H = 640, 400


def config_dir_from_argv(argv):
    if len(argv) > 3:
        return argv[3]
    return os.path.join(
        os.environ.get('XDG_CONFIG_HOME', os.path.expanduser('~/.config')),
        'ResumePad',
    )


def placement_key_for_index(index_path):
    """Edge app_window_placement 键名，如 _/home/user/src/ResumePad/index"""
    p = os.path.abspath(index_path)
    if p.endswith('.html'):
        p = p[:-5]
    return '_/' + p.lstrip('/')


def prefs_path(profile):
    return os.path.join(profile, 'Default', 'Preferences')


def bounds_file_path(config_dir):
    return os.path.join(config_dir, 'window-bounds.json')


def load_prefs(profile):
    path = prefs_path(profile)
    if not os.path.isfile(path):
        return None
    try:
        return json.load(open(path, encoding='utf-8'))
    except (OSError, json.JSONDecodeError):
        return None


def save_prefs(profile, prefs):
    path = prefs_path(profile)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(prefs, f, ensure_ascii=False, separators=(',', ':'))


def leveldb_text(profile):
    ldb_dir = os.path.join(profile, 'Default', 'Local Storage', 'leveldb')
    if not os.path.isdir(ldb_dir):
        return ''
    parts = []
    for path in glob.glob(os.path.join(ldb_dir, '*')):
        if os.path.isfile(path):
            try:
                parts.append(open(path, 'rb').read().decode('utf-8', 'ignore'))
            except OSError:
                pass
    return ''.join(parts)


def work_area(page):
    wa_l = int(page.get('work_area_left', 0))
    wa_t = int(page.get('work_area_top', 0))
    wa_r = int(page.get('work_area_right', 2560))
    wa_b = int(page.get('work_area_bottom', 1440))
    return wa_l, wa_t, max(800, wa_r - wa_l), max(600, wa_b - wa_t)


def normalize_bounds(w, h, x, y, page=None):
    if w < MIN_W or h < MIN_H:
        return dict(DEFAULT)
    if page and page.get('maximized'):
        return dict(DEFAULT)
    wa_l, wa_t, work_w, work_h = work_area(page) if page else (0, 0, 2560, 1440)
    if w > work_w * 0.96 or h > work_h * 0.96:
        return dict(DEFAULT)
    w = max(MIN_W, min(w, work_w - 20))
    h = max(MIN_H, min(h, work_h - 20))
    x = max(wa_l, min(int(x), wa_l + work_w - w))
    y = max(wa_t, min(int(y), wa_t + work_h - h))
    return {'w': w, 'h': h, 'x': x, 'y': y}


def _path_matches_resumepad(path):
    p = path.lower()
    if 'local/bin' in p:
        return False
    return 'resumepad' in p or 'app-root' in p


def _bounds_from_page(page):
    if not isinstance(page, dict):
        return None
    left, top = page.get('left'), page.get('top')
    right, bottom = page.get('right'), page.get('bottom')
    if None in (left, top, right, bottom):
        return None
    w, h = int(right - left), int(bottom - top)
    if w < MIN_W or h < MIN_H:
        return None
    return normalize_bounds(w, h, int(left), int(top), page)


def iter_placement_entries(prefs):
    """遍历 app_window_placement（含 Chromium 拆开的嵌套键）。"""
    placement = prefs.get('browser', {}).get('app_window_placement', {})
    if not isinstance(placement, dict):
        return
    for outer, data in placement.items():
        if not isinstance(data, dict):
            continue
        b = _bounds_from_page(data)
        if b:
            yield str(outer), b
            continue
        for key, node in data.items():
            if not isinstance(node, dict):
                continue
            full = f'{outer}/{key}'
            b = _bounds_from_page(node)
            if b:
                yield full, b
                continue
            for subkey, page in node.items():
                if not isinstance(page, dict):
                    continue
                sub = f'{full}/{subkey}'
                b = _bounds_from_page(page)
                if b:
                    yield sub, b


def read_placement_bounds(prefs, prefer_path=''):
    prefer = prefer_path.lower()
    fallback = None
    for path, bounds in iter_placement_entries(prefs):
        if not _path_matches_resumepad(path):
            continue
        if prefer and prefer in path.lower():
            return bounds
        if fallback is None:
            fallback = bounds
    return fallback


def read_leveldb_bounds(profile):
    text = leveldb_text(profile)
    m = re.search(
        r'resumepad_window_bounds[^\{]*(\{"w"\s*:\s*\d+\s*,\s*"h"\s*:\s*\d+\s*,\s*"x"\s*:\s*-?\d+\s*,\s*"y"\s*:\s*-?\d+\})',
        text,
    )
    if not m:
        return None
    try:
        s = json.loads(m.group(1))
        return normalize_bounds(int(s['w']), int(s['h']), int(s['x']), int(s['y']))
    except (json.JSONDecodeError, KeyError, TypeError, ValueError):
        return None


def read_bounds_file(config_dir, repair=False):
    path = bounds_file_path(config_dir)
    if not os.path.isfile(path):
        return None
    try:
        raw = open(path, encoding='utf-8').read().strip()
        if not raw:
            return None
        s = None
        try:
            s = json.loads(raw)
        except json.JSONDecodeError:
            for m in re.finditer(r'\{"w"\s*:\s*\d+\s*,\s*"h"\s*:\s*\d+\s*,\s*"x"\s*:\s*-?\d+\s*,\s*"y"\s*:\s*-?\d+\}', raw):
                try:
                    s = json.loads(m.group(0))
                except json.JSONDecodeError:
                    continue
        if not s:
            if repair:
                write_bounds_file(config_dir, dict(DEFAULT))
            return None
        b = normalize_bounds(int(s['w']), int(s['h']), int(s['x']), int(s['y']))
        if repair and b:
            write_bounds_file(config_dir, b)
        return b
    except (OSError, json.JSONDecodeError, KeyError, TypeError, ValueError):
        if repair:
            write_bounds_file(config_dir, dict(DEFAULT))
        return None


def write_bounds_file(config_dir, bounds):
    path = bounds_file_path(config_dir)
    os.makedirs(config_dir, exist_ok=True)
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(bounds, f, separators=(',', ':'))
    os.replace(tmp, path)


def _page_data(bounds):
    x, y, w, h = bounds['x'], bounds['y'], bounds['w'], bounds['h']
    return {
        'left': x,
        'top': y,
        'right': x + w,
        'bottom': y + h,
        'maximized': False,
        'work_area_left': 0,
        'work_area_top': 0,
        'work_area_right': 2560,
        'work_area_bottom': 1440,
    }


def sync_placement(prefs, bounds):
    placement = prefs.setdefault('browser', {}).setdefault('app_window_placement', {})
    if not isinstance(placement, dict):
        return
    page_data = _page_data(bounds)
    html_page = {'html': page_data}
    index_paths = []
    for env_key in ('RESUMEPAD_INDEX_PATH', 'RESUMEPAD_APP_INDEX'):
        p = os.environ.get(env_key, '')
        if p:
            index_paths.append(p)
    if not index_paths:
        index_paths.append('')
    for index_path in index_paths:
        key = placement_key_for_index(index_path) if index_path else '_/ResumePad/index'
        placement[key] = dict(html_page)
    for top_key in list(placement.keys()):
        if 'local/bin' in str(top_key).lower():
            del placement[top_key]
            continue
        node = placement.get(top_key)
        if not isinstance(node, dict):
            continue
        for sub_key in list(node.keys()):
            if 'local/bin' in str(sub_key).lower():
                del node[sub_key]
        # Chromium 误拆的 _/home/zw/ → config/.../app-root/...
        if top_key == '_/home/zw/' and not any(
            k == 'html' and isinstance(v, dict) and 'left' in v for k, v in node.items()
        ):
            del placement[top_key]
            continue
        if not node:
            del placement[top_key]


def _prefer_index_path():
    return os.environ.get('RESUMEPAD_INDEX_PATH', '') or os.environ.get(
        'RESUMEPAD_APP_INDEX', ''
    )


def resolve_bounds(profile, config_dir):
    """启动时读：优先 window-bounds.json（上次 save 写入），避免被空 Edge 配置盖掉。"""
    b = read_bounds_file(config_dir)
    if b:
        return b
    b = read_leveldb_bounds(profile)
    if b:
        return b
    prefs = load_prefs(profile)
    if prefs:
        b = read_placement_bounds(prefs, _prefer_index_path())
        if b:
            return b
    return dict(DEFAULT)


def capture_bounds_from_x11():
    """从 X11 窗口树读取（最可靠）。"""
    script = os.path.join(os.path.dirname(__file__), 'bounds-wm.py')
    if not os.path.isfile(script):
        return None
    try:
        out = subprocess.check_output(
            [sys.executable, script, 'capture'],
            text=True,
            timeout=3,
        )
        s = json.loads(out.strip())
        return normalize_bounds(int(s['w']), int(s['h']), int(s['x']), int(s['y']))
    except (subprocess.SubprocessError, json.JSONDecodeError, KeyError, TypeError, ValueError, OSError):
        return None


def capture_bounds_from_profile(profile, config_dir):
    """关闭时读：X11 → localStorage → Edge placement（不读 json，避免循环）。"""
    b = capture_bounds_from_x11()
    if b:
        return b
    b = read_leveldb_bounds(profile)
    if b:
        return b
    prefs = load_prefs(profile)
    if prefs:
        b = read_placement_bounds(prefs, _prefer_index_path())
        if b:
            return b
    return None


def read_theme(profile):
    text = leveldb_text(profile)
    if 'resumepad_theme' in text:
        if re.search(r'resumepad_theme[^\w]*dark', text):
            return 'dark'
        if re.search(r'resumepad_theme[^\w]*light', text):
            return 'light'
    return ''


def disable_translate(prefs):
    tr = prefs.get('translate')
    if not isinstance(tr, dict):
        tr = {}
    tr['enabled'] = False
    prefs['translate'] = tr
    prefs['translate_blocked_languages'] = list(
        set(prefs.get('translate_blocked_languages') or [])
        | {'en', 'zh', 'zh-CN', 'zh-TW'}
    )


def disable_background_mode(prefs):
    """关闭「关闭后继续运行」，确保关窗后 launch-app 能退出并 save。"""
    prefs['background_mode'] = {'enabled': False}
    prefs.setdefault('session', {})['exit_type'] = 'Normal'


def cmd_init(profile, config_dir):
    """首次安装/启动：创建配置目录与默认 window-bounds.json（不覆盖已有有效记录）。"""
    os.makedirs(config_dir, exist_ok=True)
    os.makedirs(profile, exist_ok=True)
    os.makedirs(os.path.join(profile, 'Default'), exist_ok=True)
    os.environ.setdefault('RESUMEPAD_CONFIG_DIR', config_dir)
    app_index = os.path.join(config_dir, 'app-root', 'index.html')
    if os.path.isfile(app_index):
        os.environ.setdefault('RESUMEPAD_APP_INDEX', app_index)
    existing = read_bounds_file(config_dir, repair=True)
    if not existing:
        write_bounds_file(config_dir, dict(DEFAULT))


def cmd_prepare(profile, config_dir):
    cmd_init(profile, config_dir)
    os.environ.setdefault('RESUMEPAD_CONFIG_DIR', config_dir)
    app_index = os.path.join(config_dir, 'app-root', 'index.html')
    if os.path.isfile(app_index):
        os.environ.setdefault('RESUMEPAD_APP_INDEX', app_index)
    bounds = resolve_bounds(profile, config_dir)
    write_bounds_file(config_dir, bounds)
    prefs = load_prefs(profile) or {}
    disable_translate(prefs)
    disable_background_mode(prefs)
    sync_placement(prefs, bounds)
    save_prefs(profile, prefs)


def cmd_save(profile, config_dir):
    """关闭时保存：优先 X11；切勿用 Edge 旧数据覆盖已有 json。"""
    os.makedirs(config_dir, exist_ok=True)
    kept = read_bounds_file(config_dir, repair=True)
    for _ in range(8):
        b = capture_bounds_from_x11()
        if b:
            write_bounds_file(config_dir, b)
            return
        time.sleep(0.2)
    if kept:
        return
    bounds = None
    for _ in range(8):
        bounds = capture_bounds_from_profile(profile, config_dir)
        if bounds and (not kept or bounds != kept):
            break
        time.sleep(0.25)
    if bounds:
        write_bounds_file(config_dir, bounds)
    elif not kept:
        write_bounds_file(config_dir, dict(DEFAULT))


def main():
    if len(sys.argv) < 3:
        sys.exit('usage: window-bounds.py init|prepare|save|read|theme <profile> [config_dir]')
    cmd, profile = sys.argv[1], sys.argv[2]
    config_dir = config_dir_from_argv(sys.argv)

    if cmd == 'init':
        cmd_init(profile, config_dir)
    elif cmd == 'prepare':
        cmd_prepare(profile, config_dir)
    elif cmd == 'save':
        cmd_save(profile, config_dir)
    elif cmd == 'read':
        print(json.dumps(resolve_bounds(profile, config_dir), separators=(',', ':')))
    elif cmd == 'theme':
        print(read_theme(profile))
    else:
        sys.exit(f'unknown command: {cmd}')


if __name__ == '__main__':
    main()
