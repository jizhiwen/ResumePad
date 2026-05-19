#!/usr/bin/env python3
"""从 X11 窗口树读取 ResumePad 应用窗口尺寸（不依赖 Edge localStorage）。"""
import json
import os
import re
import subprocess
import sys

MIN_W, MIN_H = 640, 400
DEFAULT = {'w': 960, 'h': 500, 'x': 80, 'y': 50}


def bounds_file(config_dir):
    return os.path.join(config_dir, 'window-bounds.json')


def _is_candidate_line(line):
    low = line.lower()
    if 'resumepad' not in line and 'app-root' not in low:
        return False
    if 'resume' in low and 'cursor' in low:
        return False
    if 'gnome-terminal' in low:
        return False
    if 'microsoft-edge' in low and 'resumepad' not in line:
        return False
    return (
        'app-root' in low
        or 'index.html' in low
        or 'resumepad —' in line
        or 'resumepad -' in line
        or ('"resumepad' in low and 'resumepad' in low)
    )


def find_window_line():
    try:
        out = subprocess.check_output(
            ['xwininfo', '-root', '-tree'],
            text=True,
            errors='replace',
            timeout=2,
        )
    except (subprocess.SubprocessError, FileNotFoundError, OSError):
        return None
    best = None
    best_area = 0
    for line in out.splitlines():
        if not _is_candidate_line(line):
            continue
        b = parse_line(line)
        if not b:
            continue
        area = b['w'] * b['h']
        if area > best_area:
            best_area = area
            best = line
    return best


def parse_line(line):
    # 例: 0x800004 "ResumePad — …": ("…resumepad")  777x444+10+45  +184+575
    m = re.search(
        r'(\d+)x(\d+)\+\d+\+\d+\s+\+(-?\d+)\+(-?\d+)\s*$',
        line.strip(),
    )
    if not m:
        m = re.search(r'(\d+)x(\d+)\+(-?\d+)\+(-?\d+)', line)
        if not m:
            return None
        w, h, x, y = int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4))
    else:
        w, h, x, y = int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4))
    if w < MIN_W or h < MIN_H:
        return None
    return {'w': w, 'h': h, 'x': x, 'y': y}


def capture():
    line = find_window_line()
    if not line:
        return None
    return parse_line(line)


def atomic_write_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))
    os.replace(tmp, path)


def cmd_init(config_dir):
    path = bounds_file(config_dir)
    if os.path.isfile(path):
        return 0
    atomic_write_json(path, dict(DEFAULT))
    return 0


def cmd_poll(config_dir):
    b = capture()
    if not b:
        return 1
    atomic_write_json(bounds_file(config_dir), b)
    return 0


def ensure_default_bounds(config_dir):
    """无窗口可读时仍保证配置文件存在。"""
    path = bounds_file(config_dir)
    if os.path.isfile(path):
        try:
            json.loads(open(path, encoding='utf-8').read().strip())
            return
        except (OSError, json.JSONDecodeError):
            pass
    atomic_write_json(path, dict(DEFAULT))


def main():
    if len(sys.argv) < 2:
        sys.exit('usage: bounds-wm.py init|poll|read|capture <config-dir>')
    cmd = sys.argv[1]
    if cmd == 'capture':
        b = capture()
        if not b:
            sys.exit(1)
        print(json.dumps(b, separators=(',', ':')))
        sys.exit(0)
    if len(sys.argv) < 3:
        sys.exit('usage: bounds-wm.py init|poll|read|capture <config-dir>')
    config_dir = sys.argv[2]
    if cmd == 'init':
        sys.exit(cmd_init(config_dir))
    if cmd == 'poll':
        sys.exit(cmd_poll(config_dir))
    if cmd == 'read':
        path = bounds_file(config_dir)
        if os.path.isfile(path):
            print(open(path, encoding='utf-8').read(), end='')
        else:
            print(json.dumps(DEFAULT, separators=(',', ':')))
        sys.exit(0)
    sys.exit(f'unknown command: {cmd}')


if __name__ == '__main__':
    main()
