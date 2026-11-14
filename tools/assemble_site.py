"""Assemble a local review and existing Web export; never enable hosting or deploy."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
RUNTIME_DIRS = ("game", "platform", "assets", "addons", "scenes")
RUNTIME_EXTENSIONS = {".gd", ".uid", ".json", ".tscn", ".tres", ".res", ".glb", ".gltf", ".bin", ".obj", ".mtl", ".png", ".jpg", ".jpeg", ".webp", ".svg", ".ogg", ".wav", ".mp3", ".aar", ".cfg", ".gdextension", ".gdshader", ".shader", ".ttf", ".otf", ".fnt", ".translation"}
PRIVATE_SUFFIXES = {".log", ".keystore", ".jks", ".pfx", ".p12", ".pem", ".key", ".pyc", ".apk", ".aab", ".tmp", ".bak"}
PRIVATE_FILENAMES = {"config.local.json", "local.properties", "credentials.json", "id_rsa", "id_ed25519"}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git(*arguments: str) -> str:
    return subprocess.check_output(["git", *arguments], cwd=ROOT, text=True, stderr=subprocess.PIPE).strip()


def allowed_public(path: Path) -> bool:
    return not any(part.startswith(".") or ".private." in part.lower() or part in ("__pycache__", "raw-logs") for part in path.parts) and path.suffix.lower() not in PRIVATE_SUFFIXES | {".import"} and path.name.lower() not in PRIVATE_FILENAMES


def git_blob_hashes(names: list[str]) -> dict[str, str]:
    """Hash committed content without checkout newline or file-mode conversion."""
    if any("\n" in name or "\r" in name for name in names):
        raise SystemExit("Runtime filenames cannot contain line breaks")
    request = "".join(f"HEAD:{name}\n" for name in names).encode("utf-8")
    result = subprocess.run(["git", "cat-file", "--batch"], input=request, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, check=True, cwd=ROOT)
    data, position, hashes = result.stdout, 0, {}
    for name in names:
        line_end = data.find(b"\n", position)
        fields = data[position:line_end].split() if line_end >= 0 else []
        if len(fields) != 3 or fields[1] != b"blob" or not fields[2].isdigit():
            raise SystemExit(f"Committed runtime blob unavailable: {name}")
        length = int(fields[2])
        start, end = line_end + 1, line_end + 1 + length
        if end >= len(data) or data[end:end + 1] != b"\n":
            raise SystemExit(f"Truncated committed runtime blob: {name}")
        hashes[name] = sha256(data[start:end])
        position = end + 1
    if position != len(data):
        raise SystemExit("Unexpected extra Git blob output")
    return hashes


def source_identity(require_clean: bool, expected_sha: str | None) -> dict:
    try:
        # A parent workspace repository is not this game's public source identity.
        if Path(git("rev-parse", "--show-toplevel")).resolve() != ROOT:
            raise ValueError("Game is not its own repository")
        commit = git("rev-parse", "HEAD")
        changes = git("status", "--porcelain", "--untracked-files=all").splitlines()
        names = git("ls-files", "--cached", "--others", "--exclude-standard", "-z").split("\0")
    except (OSError, subprocess.CalledProcessError, ValueError):
        if require_clean or expected_sha:
            raise SystemExit("A committed game Git checkout is required for verified assembly.")
        commit, changes = None, ["Game source is not committed"]
        names = [path.relative_to(ROOT).as_posix() for folder in RUNTIME_DIRS for path in (ROOT / folder).rglob("*") if path.is_file()]
    dirty = bool(changes)
    if expected_sha and commit != expected_sha:
        raise SystemExit(f"Checkout mismatch: expected {expected_sha}, found {commit}")
    if require_clean and dirty:
        raise SystemExit("Refusing verified assembly: source changes exist after import/export.")
    runtime = {}
    for name in names:
        relative = Path(name)
        if relative.parts and relative.parts[0] in RUNTIME_DIRS and relative.suffix.lower() in RUNTIME_EXTENSIONS and allowed_public(relative):
            path = ROOT / relative
            if not path.is_file():
                raise SystemExit(f"Missing runtime source: {name}")
            runtime[relative.as_posix()] = sha256(path.read_bytes())
    for name in ("project.godot", "export_presets.cfg"):
        path = ROOT / name
        if not path.is_file():
            raise SystemExit(f"Missing runtime source: {name}")
        runtime[name] = sha256(path.read_bytes())
    worktree_digest = sha256(json.dumps(runtime, sort_keys=True).encode())
    if not dirty:
        runtime = git_blob_hashes(sorted(runtime))
    digest = sha256(json.dumps(runtime, sort_keys=True).encode())
    return {
        "game": "Cinderbrook Brigade", "source_commit": commit,
        "uncommitted_changes": dirty, "working_tree_changes": changes,
        "runtime_tree_sha256": digest, "runtime_files": runtime,
        "runtime_hash_basis": "working-tree bytes of local uncommitted source" if dirty else "canonical committed Git blob bytes",
        "runtime_worktree_tree_sha256": worktree_digest,
        "runtime_hash_scope": ("Local runtime-format files in game/platform/assets/addons/scenes and project/export settings; Git-visible paths when a repository exists, otherwise a filesystem snapshot. This uncommitted snapshot is not a canonical export proof." if dirty else "Tracked runtime-format inputs in game/platform/assets/addons/scenes and project/export settings; canonical Git blobs avoid checkout newline conversion. Ignored plugin installation files and Godot caches excluded."),
        "source_identity": f"local-uncommitted/{digest}" if dirty else commit,
        "engine": "4.5.1.stable", "web_threads": False,
        "assembly_is_deployment": False,
    }


def copy_public(source: Path, destination: Path, target: Path) -> None:
    if not destination.resolve().is_relative_to(target):
        raise SystemExit("Managed output escapes site directory")
    if destination.exists():
        shutil.rmtree(destination)
    destination.mkdir(parents=True)
    for path in sorted(source.rglob("*")):
        relative = path.relative_to(source)
        if not path.is_file() or not allowed_public(relative):
            continue
        if path.is_symlink() or not path.resolve().is_relative_to(ROOT):
            raise SystemExit(f"Refusing public symlink or external file: {relative}")
        output = destination / relative
        output.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, output)


def assemble(target: Path, require_clean: bool = False, expected_sha: str | None = None) -> dict:
    target = target.resolve()
    build_root = (ROOT / "build").resolve()
    if target == build_root or not target.is_relative_to(build_root):
        raise SystemExit("Site output must be a subdirectory of this project's build/ directory.")
    if not (target / "play/index.html").is_file():
        raise SystemExit("Export Web to <site>/play/index.html first.")
    (target / "build.json").unlink(missing_ok=True)
    identity = source_identity(require_clean, expected_sha)
    web_html = target / "play/index.html"
    html = web_html.read_text(encoding="utf-8")
    marker = "const engine = new Engine(GODOT_CONFIG);"
    guard_marker = "// CINDERBROOK_ENGINE_GUARD"
    if marker not in html:
        raise SystemExit("Cannot locate official Web shell engine startup for compatibility diagnostic.")
    guard = '''// CINDERBROOK_ENGINE_GUARD: the official engine JavaScript remains unmodified.
if (typeof Engine !== 'function') {
  document.body.innerHTML = '<main style="max-width:640px;margin:12vh auto;padding:28px;color:#fff5df;background:#173a3d;font:18px/1.6 system-ui;border-radius:16px"><h1>Update your browser to play</h1><p>This browser could not load the Godot game engine. Please use a current browser with WebGL 2 support.</p><p><a style="color:#97e8c4" href="../review/">Open Cinderbrook Brigade screenshots and review</a></p></main>';
  throw new Error('Cinderbrook Brigade: game engine unavailable; update the browser.');
}
'''
    if guard_marker in html:
        start = html.index(guard_marker)
        end = html.index(marker, start)
        html = html[:start] + guard + html[end:]
    else:
        html = html.replace(marker, guard + marker)
    web_html.write_text(html, encoding="utf-8", newline="\n")
    for folder in ("review", "marketing", "docs", "LICENSES"):
        source = ROOT / folder
        if not source.is_dir():
            raise SystemExit(f"Missing site source directory: {folder}")
        copy_public(source, target / folder, target)
    public = ROOT / "public/index.html"
    if not public.is_file():
        raise SystemExit("Missing public landing page")
    shutil.copy2(public, target / "index.html")
    for path in sorted((ROOT / "public").iterdir()):
        if path.name == "index.html" or not allowed_public(Path(path.name)):
            continue
        if path.name in {"play", "review", "marketing", "docs", "LICENSES", "assets", "game", "build.json"}:
            raise SystemExit(f"Public source collides with managed site output: {path.name}")
        if path.is_dir():
            copy_public(path, target / path.name, target)
        else:
            shutil.copy2(path, target / path.name)
    for name in ("LICENSE", "NOTICE", "INITIAL_VECTOR_PROMPT.txt"):
        shutil.copy2(ROOT / name, target / name)
    assets = target / "assets"
    if assets.exists():
        if not assets.resolve().is_relative_to(target):
            raise SystemExit("Asset output escapes site directory")
        shutil.rmtree(assets)
    for folder in ("brand", "achievements", "leaderboards", "ui"):
        if (ROOT / "assets" / folder).is_dir():
            copy_public(ROOT / "assets" / folder, assets / folder, target)
    game = target / "game"
    if game.exists():
        if not game.resolve().is_relative_to(target):
            raise SystemExit("Catalog output escapes site directory")
        shutil.rmtree(game)
    game.mkdir()
    shutil.copy2(ROOT / "game/catalog.json", game / "catalog.json")
    shutil.copy2(ROOT / "game/catalog.json", target / "catalog.json")
    (target / ".nojekyll").touch()
    identity["web_export_sha256"] = {path.relative_to(target).as_posix(): sha256(path.read_bytes()) for path in sorted((target / "play").rglob("*")) if path.is_file()}
    if require_clean and git("status", "--porcelain", "--untracked-files=all"):
        raise SystemExit("Source became dirty during assembly; refusing verified build metadata.")
    (target / "build.json").write_text(json.dumps(identity, indent=2) + "\n", encoding="utf-8", newline="\n")
    return identity


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", nargs="?", type=Path, default=ROOT / "build/site")
    parser.add_argument("--require-clean", action="store_true")
    parser.add_argument("--expected-sha")
    args = parser.parse_args()
    identity = assemble(args.target, args.require_clean, args.expected_sha)
    print(f"Assembled {args.target} from {identity['source_identity']}; this does not deploy it.")


if __name__ == "__main__":
    main()
