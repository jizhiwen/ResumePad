#!/usr/bin/env python3
"""
ResumePad 独立窗口辅助脚本（由 launch-app.sh 调用，勿单独运行）。

子命令：
  prepare  启动前：读 window-bounds.json（上次关闭时写入），同步到 Edge Preferences。
  save     关闭后：从 Edge / localStorage 读出窗口信息，写入 window-bounds.json。
  read     输出 JSON：{"w","h","x","y"}，供 launch-app 传入 --window-size/position。
  theme    输出 dark 或 light（空为未设置），供 launch-app 设置 --background-color。

用法：window-bounds.py <prepare|save|read|theme> <edge-profile-dir> [config-dir]
config-dir 默认为 ~/.config/ResumePad。
"""
import glob
import json
import os
import re
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


def read_placement_bounds(prefs):
    placement = prefs.get('browser', {}).get('app_window_placement', {})
    if not isinstance(placement, dict):
        return None
    for path, data in placement.items():
        if 'ResumePad' not in path and 'resumepad' not in path.lower():
            continue
        if not isinstance(data, dict):
            continue
        for page in data.values():
            if not isinstance(page, dict):
                continue
            left, top = page.get('left'), page.get('top')
            right, bottom = page.get('right'), page.get('bottom')
            if None in (left, top, right, bottom):
                continue
            w, h = int(right - left), int(bottom - top)
            if w >= MIN_W and h >= MIN_H:
                return normalize_bounds(w, h, int(left), int(top), page)
    return None


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


def read_bounds_file(config_dir):
    path = bounds_file_path(config_dir)
    if not os.path.isfile(path):
        return None
    try:
        s = json.load(open(path, encoding='utf-8'))
        return normalize_bounds(int(s['w']), int(s['h']), int(s['x']), int(s['y']))
    except (OSError, json.JSONDecodeError, KeyError, TypeError, ValueError):
        return None


def write_bounds_file(config_dir, bounds):
    os.makedirs(config_dir, exist_ok=True)
    with open(bounds_file_path(config_dir), 'w', encoding='utf-8') as f:
        json.dump(bounds, f, separators=(',', ':'))


def sync_placement(prefs, bounds):
    placement = prefs.setdefault('browser', {}).setdefault('app_window_placement', {})
    if not isinstance(placement, dict):
        return
    x, y, w, h = bounds['x'], bounds['y'], bounds['w'], bounds['h']
    page_data = {
        'left': x,
        'top': y,
        'right': x + w,
        'bottom': y + h,
        'maximized': False,
    }
    updated = False
    for path, pages in list(placement.items()):
        if 'ResumePad' not in path and 'resumepad' not in path.lower():
            continue
        if not isinstance(pages, dict):
            continue
        for page_key in pages:
            if isinstance(pages[page_key], dict):
                pages[page_key] = {**pages[page_key], **page_data}
                updated = True
    if not updated:
        index_path = os.environ.get('RESUMEPAD_INDEX_PATH', '')
        key = placement_key_for_index(index_path) if index_path else '_/ResumePad/index'
        placement[key] = {
            'html': {
                **page_data,
                'work_area_left': 0,
                'work_area_top': 0,
                'work_area_right': 2560,
                'work_area_bottom': 1440,
            }
        }


def resolve_bounds(profile, config_dir):
    """启动时读：优先 window-bounds.json（上次 save 写入），避免被空 Edge 配置盖掉。"""
    b = read_bounds_file(config_dir)
    if b:
        return b
    prefs = load_prefs(profile)
    if prefs:
        b = read_placement_bounds(prefs)
        if b:
            return b
    b = read_leveldb_bounds(profile)
    if b:
        return b
    return dict(DEFAULT)


def capture_bounds_from_profile(profile, config_dir):
    """关闭时读：优先 Edge 刚写入的 Preferences，其次页面 localStorage。"""
    prefs = load_prefs(profile)
    if prefs:
        b = read_placement_bounds(prefs)
        if b:
            return b
    b = read_leveldb_bounds(profile)
    if b:
        return b
    return read_bounds_file(config_dir)


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


def cmd_prepare(profile, config_dir):
    os.makedirs(config_dir, exist_ok=True)
    bounds = resolve_bounds(profile, config_dir)
    prefs = load_prefs(profile) or {}
    disable_translate(prefs)
    sync_placement(prefs, bounds)
    save_prefs(profile, prefs)


def cmd_save(profile, config_dir):
    os.makedirs(config_dir, exist_ok=True)
    bounds = None
    for _ in range(12):
        bounds = capture_bounds_from_profile(profile, config_dir)
        if bounds:
            break
        time.sleep(0.25)
    if not bounds:
        bounds = resolve_bounds(profile, config_dir)
    write_bounds_file(config_dir, bounds)


def main():
    if len(sys.argv) < 3:
        sys.exit('usage: window-bounds.py prepare|save|read|theme <profile> [config_dir]')
    cmd, profile = sys.argv[1], sys.argv[2]
    config_dir = config_dir_from_argv(sys.argv)

    if cmd == 'prepare':
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
