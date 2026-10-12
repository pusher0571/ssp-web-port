"""Run format tests without the game's autoloads or imported graphical assets."""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--godot', required=True)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
scratch = (repo / 'build').resolve()
scratch.mkdir(exist_ok=True)
assert scratch.parent == repo.resolve()
with tempfile.TemporaryDirectory(prefix='settings-code-test-', dir=scratch) as folder:
    project = Path(folder).resolve()
    assert project.parent == scratch
    (project / 'project.godot').write_text('config_version=4\n', encoding='utf-8')
    for name in ['scripts/web/SettingsCode.gd', 'tools/test_settings_code.gd']:
        target = project / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(repo / name, target)
    result = subprocess.run(
        [args.godot, '--no-window', '--path', str(project), '--script', 'res://tools/test_settings_code.gd'],
        capture_output=True, text=True, timeout=30,
    )
    log = result.stdout + result.stderr
    print(log.strip())
    if result.returncode or 'Settings-code tests: PASS' not in log or 'FAIL:' in log:
        raise SystemExit(1)
