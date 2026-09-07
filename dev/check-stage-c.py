#!/usr/bin/env python3
"""Exercise emitted bytes with an independently built loader rig."""
import argparse
import json
import os
from pathlib import Path
import struct
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rig", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    rig = args.rig.resolve()
    binary = repo / "_build/default/bin/tally.exe"
    ledger = repo / "dev/CITATION-LEDGER.md"
    env = dict(os.environ, TOT_PRELUDE=str(repo / "vendor/tot/stdlib/prelude.tot"))
    commands = []
    checks = []

    def run(name, command, expected=0, stdin=None):
        result = subprocess.run(list(map(str, command)), cwd=repo, env=env,
                                input=stdin, capture_output=True, text=True)
        (out / (name + ".stdout")).write_text(result.stdout)
        (out / (name + ".stderr")).write_text(result.stderr)
        commands.append({"name": name, "command": list(map(str, command)),
                         "expected": expected, "status": result.returncode})
        check(name + " status", result.returncode == expected)
        return result.stdout + result.stderr

    def check(name, passed):
        checks.append({"name": name, "passed": bool(passed)})

    run("target-tests", [repo / "_build/default/test/target_test.exe"], stdin=ledger.read_text())
    image_text = run("image-tests", [repo / "_build/default/test/image_test.exe", ledger])
    case_text = run("emitter-tests", [repo / "_build/default/test/emitter_test.exe", ledger])
    cases = []
    for line in (image_text + case_text).splitlines():
        if line.startswith("IMAGE "):
            _, name, encoded = line.split()
            expected = "0"
        elif line.startswith("CASE "):
            _, name, expected, encoded = line.split()
        else:
            continue
        image = out / (name + ".so")
        image.write_bytes(bytes.fromhex(encoded))
        run("machine-" + name, [rig, "--run", "--expect", expected, image])
        cases.append(name)
    check("machine corpus nonempty", len(cases) >= 103)
    check("machine names unique", len(cases) == len(set(cases)))

    fixtures = ["smoke-log", "smoke-ret", "emit-div-zero", "emit-mod-zero",
                "emit-sdiv-min-neg1", "emit-srem-min-neg1", "emit-shift-width"]
    for name in fixtures:
        image = out / (name + ".so")
        source = repo / "test/fixtures" / (name + ".tot")
        run("build-" + name, [binary, "build", "-o", image, source])
        expected = source.with_suffix(".expected").read_text().strip()
        run("run-" + name, [rig, "--run", "--expect", expected, image])
        check(name + " manifest exists", image.with_suffix(".so.manifest").is_file())
    native = run("native-convention", [binary, "build", "-o", out / "native.so",
        repo / "test/fixtures/emit-frame-call.tot"], expected=2)
    check("native convention typed rejection", "Row_unverified S18" in native)
    check("native produces no image", not (out / "native.so").exists())
    run("return-negative", [rig, "--run", "--expect", "1", out / "smoke-ret.so"], expected=1)
    # An option that takes a path never swallows a following recognised flag:
    # doing so named a real artifact after the option the user meant to pass.
    # The driver parser is not library-exposed, so this regression lives here.
    for flag, following in (("-o", "--ledger"), ("--ledger", "-o")):
        rejected = run("flag-argument" + flag, [binary, "build", flag, following,
            repo / "test/fixtures/smoke-ret.tot"], expected=2)
        check(flag + " rejects a following flag as its path",
              "output and ledger options require a path" in rejected)
        check(flag + " writes no artifact named " + following,
              not (repo / following).exists())
    ours = run("compiler-keys", [binary, "build", "--print-syscall-keys"])
    theirs = run("oracle-keys", [rig, "--syscall-keys"])
    check("independent syscall keys", ours == theirs and len(ours.splitlines()) == 3)

    reference = out / "cterm-reference"
    run("cterm-reference", [repo / "_build/default/test/cterm_ref.exe", reference])
    check("ten Stage B differential cases", (reference / "interp.txt").read_text() ==
          (reference / "pipeline.txt").read_text() and
          len((reference / "interp.txt").read_text().splitlines()) == 10)

    # Each rejected output naming pattern must preserve the source bytes.
    source_text = "def main : U64 := 7u64\n"
    protected = out / "protected.tot"
    protected.write_text(source_text)
    aliases = [protected, out / "." / "protected.tot", out / "protected-link.tot",
               out / "protected-hardlink.tot"]
    for link in aliases[2:]:
        if link.exists() or link.is_symlink():
            link.unlink()
    aliases[2].symlink_to(protected.name)
    os.link(protected, aliases[3])
    for index, alias in enumerate(aliases):
        run("protect-alias-" + str(index), [binary, "build", "-o", alias, protected], expected=2)
        check("source preserved " + str(index), protected.read_text() == source_text)
    manifest_source = out / "protected-output.manifest"
    manifest_source.write_text(source_text)
    run("protect-manifest", [binary, "build", "-o", out / "protected-output", manifest_source], expected=2)
    check("manifest source preserved", manifest_source.read_text() == source_text)
    directory = out / "output-directory"
    directory.mkdir(exist_ok=True)
    previous = Path(str(directory) + ".manifest")
    previous.write_text("previous manifest\n")
    run("output-directory", [binary, "build", "-o", directory, protected], expected=2)
    check("failed output preserves manifest", previous.read_text() == "previous manifest\n")

    # Mutations alter emitted artifacts, with pristine bytes retained on disk.
    floor = (out / "floor.so").read_bytes()
    mutations = {}
    changed = bytearray(floor)
    changed[48] = 255
    mutations["version"] = bytes(changed)
    mutations["truncated"] = floor[:32]
    changed = bytearray(floor)
    changed[64:120], changed[120:176] = changed[120:176], changed[64:120]
    mutations["header-order"] = bytes(changed)
    text_offset = struct.unpack_from("<Q", floor, 72)[0]
    changed = bytearray(floor)
    changed[text_offset + 8] = 0x95
    mutations["return-opcode"] = bytes(changed)
    for name, content in mutations.items():
        image = out / ("mutant-" + name + ".so")
        image.write_bytes(content)
        run("mutant-" + name, [rig, "--run", "--expect", "0", image], expected=1)
        run("restore-" + name, [rig, "--run", "--expect", "0", out / "floor.so"])
        check("pristine preserved " + name, (out / "floor.so").read_bytes() == floor)

    for name, fixture, before, after, diagnostic in [
        ("division-guard", "emit-div-zero", 0x15, 0x55, "DivideByZero"),
        ("shift-guard", "emit-shift-width", 0x35, 0x25, "return mismatch"),
        ("syscall-key", "smoke-log", 0x95, 0x95, "InvalidSyscall"),
    ]:
        pristine = (out / (fixture + ".so")).read_bytes()
        changed = bytearray(pristine)
        offset = struct.unpack_from("<Q", pristine, 72)[0]
        size = struct.unpack_from("<Q", pristine, 96)[0]
        sites = [pc for pc in range(offset, offset + size, 8) if changed[pc] == before]
        check("mutation site " + name, bool(sites))
        if sites:
            pc = sites[0]
            changed[pc] = after
            if name == "syscall-key":
                changed[pc + 4:pc + 8] = bytes(4)
            image = out / ("mutant-" + name + ".so")
            image.write_bytes(changed)
            text = run("mutant-" + name, [rig, "--run", "--expect", "0", image], expected=1)
            check("mutation diagnostic " + name, diagnostic in text)
            run("restore-" + name, [rig, "--run", "--expect", "0", out / (fixture + ".so")])
            check("pristine preserved " + name, (out / (fixture + ".so")).read_bytes() == pristine)

    (out / "commands.json").write_text(json.dumps(commands, indent=2) + "\n")
    summary = {"machine_images": len(cases), "source_fixtures": len(fixtures),
               "commands": len(commands), "checks": checks}
    (out / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    failed = [item["name"] for item in checks if not item["passed"]]
    print(json.dumps({"machine_images": len(cases), "source_fixtures": len(fixtures),
                      "commands": len(commands), "failures": failed}))
    return bool(failed)


if __name__ == "__main__":
    raise SystemExit(main())
