"""Validate inactive service configuration and optionally packaged native ELF ABIs."""
from pathlib import Path
import argparse, hashlib, json, re, struct, zipfile

parser = argparse.ArgumentParser()
parser.add_argument('--artifact', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
config = json.loads((root / 'platform/config.json').read_text(encoding='utf-8'))
catalog = json.loads((root / 'game/catalog.json').read_text(encoding='utf-8'))
presets = (root / 'export_presets.cfg').read_text(encoding='utf-8')
assert len(catalog['achievements']) == 20 and len(catalog['leaderboards']) == 3
assert all(row.get('type') == 'standard' and row.get('steps', 0) in (0, None, '') for row in catalog['achievements']), 'Runtime uses Standard unlocks; incremental types require step submissions'
assert config['schema_version'] == 1
assert config['admob']['test_mode'] is True
assert all(config['admob'][kind + '_unit_id'] == '' for kind in ('banner','interstitial','rewarded')), 'Production unit placeholders must remain blank'
project = (root / 'project.godot').read_text(encoding='utf-8')
assert 'general/android/app_id="ca-app-pub-3940256099942544~3347511713"' in project, 'Operative manifest app ID must be Google sample'
autoloads = re.findall(r'^([A-Za-z][A-Za-z0-9_]*)="\*res://.*"$', project, re.M)
assert 'GodotPlayGameServices' in autoloads and 'Services' in autoloads
assert autoloads.index('GodotPlayGameServices') < autoloads.index('Services'), 'Native wrapper autoload must precede adapter'
assert config['admob']['app_id'] == 'ca-app-pub-3940256099942544~3347511713'
assert config['play_games']['enabled'] is False and config['play_games']['game_id'] == ''
for section in ('achievements', 'leaderboards'):
    assert set(config['play_games'][section]) == {row['id'] for row in catalog[section]}, section
    assert all(value == '' for value in config['play_games'][section].values()), section
for index in (0, 2):
    block = presets.split(f'[preset.{index}.options]')[1].split('[preset.')[0]
    for required in ('gradle_build/use_gradle_build=true', 'gradle_build/min_sdk="24"', 'gradle_build/target_sdk="36"',
                     'architectures/arm64-v8a=true', 'architectures/x86_64=true', 'architectures/x86=true',
                     'package/unique_name="com.ethannyakabuski.cinderbrookbrigade"', 'godot_play_game_services/game_id=""'):
        assert required in block, required
assert 'gradle_build/export_format=1' in presets.split('[preset.1]')[0]
web = presets.split('[preset.1.options]')[1].split('[preset.2]')[0]
assert 'variant/thread_support=false' in web
assert (root / 'android/.gdignore').exists(), 'Generated Android assets must never be scanned as project resources'
assert not list((root / 'addons/admob').rglob('admob_sample*')), 'unused sample translations must be absent'
libraries = []
for path in sorted((root / 'addons').rglob('*.aar')):
    with zipfile.ZipFile(path) as archive:
        assert 'classes.jar' in archive.namelist(), path
    libraries.append({'path': path.relative_to(root).as_posix(), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
assert len(libraries) == 6, 'Expected PGS debug/release and Poing core+ads debug/release'
expected_libraries = json.loads((root / 'platform/plugin-binaries.json').read_text(encoding='utf-8'))['libraries']
assert {row['path']: row['sha256'] for row in libraries} == {row['path'] : row['sha256'] for row in expected_libraries}, 'Plugin binary hash mismatch'
report = {'configuration': 'pass', 'catalog_achievements': len(catalog['achievements']), 'catalog_boards': len(catalog['leaderboards']), 'libraries': libraries}
if args.artifact:
    expected = {'arm64-v8a': (2, 183), 'x86_64': (2, 62), 'x86': (1, 3)}
    abis = {}
    with zipfile.ZipFile(args.artifact) as archive:
        for name in archive.namelist():
            match = re.search(r'(?:^|/)lib/([^/]+)/([^/]+\.so)$', name)
            if not match:
                continue
            abi, library = match.groups()
            content = archive.read(name)
            assert content[:4] == b'\x7fELF', name
            endian = '<' if content[5] == 1 else '>'
            assert (content[4], struct.unpack_from(endian + 'H', content, 18)[0]) == expected[abi], name
            abis.setdefault(abi, set()).add(library)
    assert {'arm64-v8a', 'x86_64', 'x86'} <= set(abis), abis
    assert abis['x86'] <= abis['x86_64'], 'Every x86 native library requires its x86_64 counterpart'
    assert abis['arm64-v8a'] == abis['x86_64'], '64-bit native payloads must match'
    report['artifact'] = {'path': str(args.artifact), 'sha256': hashlib.sha256(args.artifact.read_bytes()).hexdigest(), 'native_libraries': {key: sorted(value) for key, value in abis.items()}}
print(json.dumps(report, indent=2))
