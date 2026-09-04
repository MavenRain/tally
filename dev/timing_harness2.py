"""timing_harness2.py -- probe-3's harness, GENERALIZED (M0-PLAN.md Stage A row).

usage: timing_harness2.py BASE_BIN CAND_BIN CORPUS OUTDIR BASE_PRELUDE CAND_PRELUDE

The timing method is probe-3's, kept: time.perf_counter(), the cache dir
reset before the cold run, 20 warm runs.  What is parameterized is WHICH
binaries, WHICH corpus file, WHERE the outputs land, and WHICH prelude each
binary loads (TOT_PRELUDE is the only override of exe-relative resolution,
so the two binaries need one value EACH).

Exit contract: exit 0 with OUTDIR populated; exit 3 on a missing binary, a
missing prelude argument, or a non-zero check exit -- never a silent
microsecond "fast" number.
"""

import os
import shutil
import statistics
import subprocess
import sys
import time

N_WARM = 20
JITTER_LIMIT = 0.15


def die3(msg):
    sys.stderr.write("timing_harness2: " + msg + "\n")
    sys.exit(3)


def run_once(binary, prelude, cache, corpus):
    env = dict(os.environ)
    env["TOT_CACHE_DIR"] = cache
    env["TOT_PRELUDE"] = prelude
    t0 = time.perf_counter()
    p = subprocess.run([binary, "check", corpus], env=env,
                       stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    t1 = time.perf_counter()
    if p.returncode != 0:
        die3("check exited %d for %s on %s\n%s"
             % (p.returncode, binary, corpus,
                p.stderr.decode("utf-8", "replace")))
    return (t1 - t0) * 1000.0


def measure(binary, prelude, cache, corpus):
    if os.path.isdir(cache):
        shutil.rmtree(cache)
    os.makedirs(cache, exist_ok=True)
    cold_ms = run_once(binary, prelude, cache, corpus)
    warm = [run_once(binary, prelude, cache, corpus) for _ in range(N_WARM)]
    return {
        "cold_ms": cold_ms,
        "median_ms": statistics.median(warm),
        "stdev_ms": statistics.stdev(warm),
    }


def noisy(m):
    return m["median_ms"] <= 0.0 or (m["stdev_ms"] / m["median_ms"]) > JITTER_LIMIT


def us(ms):
    return int(round(ms * 1000.0))


def capture(argv):
    try:
        p = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    except OSError:
        return "unavailable"
    if p.returncode != 0:
        return "unavailable"
    return p.stdout.decode("utf-8", "replace").strip() or "unavailable"


def machine_line():
    cpu = capture(["sysctl", "-n", "machdep.cpu.brand_string"])
    osv = capture(["sw_vers", "-productVersion"])
    osb = capture(["sw_vers", "-buildVersion"])
    dune = capture(["dune", "--version"])
    if dune == "unavailable":
        dune = capture(["opam", "exec", "--", "dune", "--version"])
    ocaml = capture(["ocamlc", "-version"])
    if ocaml == "unavailable":
        ocaml = capture(["opam", "exec", "--", "ocamlc", "-version"])
    return ("machine: CPU %s; macOS %s build %s; dune %s; OCaml %s"
            % (cpu, osv, osb, dune, ocaml))


def main(argv):
    if len(argv) != 7:
        die3("usage: timing_harness2.py BASE_BIN CAND_BIN CORPUS OUTDIR "
             "BASE_PRELUDE CAND_PRELUDE")
    base_bin, cand_bin, corpus, outdir, base_prelude, cand_prelude = argv[1:]
    for path, what in ((base_bin, "BASE_BIN"), (cand_bin, "CAND_BIN")):
        if not os.path.isfile(path) or not os.access(path, os.X_OK):
            die3("missing or non-executable %s: %s" % (what, path))
    for path, what in ((base_prelude, "BASE_PRELUDE"),
                       (cand_prelude, "CAND_PRELUDE")):
        if not os.path.isfile(path):
            die3("missing %s: %s" % (what, path))
    if not os.path.isfile(corpus):
        die3("missing CORPUS: %s" % corpus)
    os.makedirs(outdir, exist_ok=True)

    base_cache = os.path.join(outdir, "cache-base")
    cand_cache = os.path.join(outdir, "cache-cand")

    base = measure(base_bin, base_prelude, base_cache, corpus)
    cand = measure(cand_bin, cand_prelude, cand_cache, corpus)
    jitter = "JITTER-OK"
    if noisy(base) or noisy(cand):
        # E2's ONE internal re-run rule.
        base = measure(base_bin, base_prelude, base_cache, corpus)
        cand = measure(cand_bin, cand_prelude, cand_cache, corpus)
        if noisy(base) or noisy(cand):
            jitter = "JITTER-NOISY"

    with open(corpus, "r") as fh:
        lines = sum(1 for _ in fh)

    values = (
        ("base-cold.txt", us(base["cold_ms"])),
        ("base-warm-median.txt", us(base["median_ms"])),
        ("base-stdev.txt", us(base["stdev_ms"])),
        ("cand-cold.txt", us(cand["cold_ms"])),
        ("cand-warm-median.txt", us(cand["median_ms"])),
        ("cand-stdev.txt", us(cand["stdev_ms"])),
    )
    for name, value in values:
        with open(os.path.join(outdir, name), "w") as fh:
            fh.write("%d\n" % value)

    ratio = (cand["median_ms"] / base["median_ms"]) if base["median_ms"] > 0 else 0.0
    verdict = "PASS" if us(cand["median_ms"]) <= 2 * us(base["median_ms"]) else "FAIL"
    with open(os.path.join(outdir, "speed-table.md"), "w") as fh:
        fh.write("| file | lines | BASE cold | BASE warm20 median | BASE stdev |"
                 " CAND cold | CAND warm20 median | CAND stdev | ratio |"
                 " verdict |\n")
        fh.write("|---|---|---|---|---|---|---|---|---|---|\n")
        fh.write("| %s | %d | %d | %d | %d | %d | %d | %d | %.3f | %s |\n"
                 % (os.path.basename(corpus), lines,
                    us(base["cold_ms"]), us(base["median_ms"]), us(base["stdev_ms"]),
                    us(cand["cold_ms"]), us(cand["median_ms"]), us(cand["stdev_ms"]),
                    ratio, verdict))
        fh.write("\nAll times are integer MICROSECONDS (perf_counter), "
                 "warm20 median of %d runs after one cold run per binary.\n"
                 % N_WARM)
        fh.write("%s\n" % machine_line())
        fh.write("BASE_BIN %s (prelude %s)\n" % (base_bin, base_prelude))
        fh.write("CAND_BIN %s (prelude %s)\n" % (cand_bin, cand_prelude))
        fh.write("jitter %s\n" % jitter)

    with open(os.path.join(outdir, "jitter.txt"), "w") as fh:
        fh.write("%s\n" % jitter)

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
