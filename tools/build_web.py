"""Build with Godot 3.6.2. Run from any directory; output is always dist/."""
import argparse, pathlib, shutil, subprocess

root = pathlib.Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--godot', required=True)
args = parser.parse_args()
dist = root / 'dist'
dist.mkdir(exist_ok=True)
subprocess.run([args.godot, '--no-window', '--path', str(root), '--export', 'Web', str(dist / 'index.html')], cwd=root, check=True)
shutil.copy(root/'web/proxy-config.js', dist/'proxy-config.js')
(dist/'.nojekyll').touch()
for name in ['index.html', 'index.js', 'index.wasm', 'index.pck', 'proxy-config.js']:
    path = dist/name
    if not path.exists() or not path.stat().st_size: raise RuntimeError(f'Missing or empty export: {name}')
print(f'Web build: {sum(p.stat().st_size for p in dist.iterdir() if p.is_file()) / 1048576:.1f} MiB')
