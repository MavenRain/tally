# Stage C status

The compiler now emits and independently executes leaf sBPF V3 images.
Native calls and closure/continuation execution remain blocked on the
unratified S18 calling convention. Constructor payloads and dynamic string
construction are not implemented in this slice. Stage C is not complete,
and Stage D must not open yet.

Build with the pinned OCaml toolchain:

```sh
dune build bin/tally.exe test/target_test.exe test/image_test.exe test/emitter_test.exe test/cterm_ref.exe
```

`tally build -o IMAGE FILE` writes IMAGE and IMAGE.manifest. Set TOT_PRELUDE
to the vendored prelude as for the Stage B CLI. `--ledger FILE` selects a
citation ledger; otherwise the driver resolves the ledger relative to its
normal Dune executable location. `--emit-none` retains the middle-end path
and is required for reference interpreter flags.

The separately built loader uses pinned source dependencies under tally-m1.
Once it is built, run the reproducible independent validation:

```sh
python3 -P dev/check-stage-c.py --rig /Users/oobi/Documents/tally-m1/rig/target/debug/loadcheck --out /private/tmp/tally-stage-c-checks
```

The checked corpus contains 103 emitted images and seven source fixtures.
The script records expected failures as well as successes and preserves
pristine bytes during artifact mutations. Its summary is scoped evidence,
not full milestone acceptance. The main battery must continue to stop at
OPEN-T1-EMIT until S18 is ratified and its dependent implementation lands.

Next work: implement the ratified calling convention and native/closure
execution, constructor payloads, the remaining source-level mutations,
and the complete Stage C acceptance run. See dev/M1-BUILD-LOG.md for the
validated slice and deviations. The second-author image is provisioned;
its generated deployment keypair is not a source or staged artifact.

## Reach of T1-14 and T1-15 in this slice

`dev/gates-tally-m1.sh` is `set -e` and T1-13 exits at OPEN-T1-EMIT while row
S18 is UNVERIFIED, so T1-14 and T1-15 cannot run in a full battery of this
slice. Both leg bodies were rerun by hand at review round 1 against image
bytes rebuilt from `test/fixtures/smoke-log.tot` and read by
`rig/target/debug/loadcheck --headers`; both exit zero. That run, its four
`hdr-*.txt` captures and the loadcheck digest are in
`tally-m1/stage-c-validation/review-r1-legs-and-mutations.log`. Treat both
entries as scoped evidence, not as battery passes, until S18 is ratified.

`dev/check-stage-c.py` also holds the driver's option contract: `-o` and
`--ledger` reject a following recognised flag rather than consuming it as
their path.
