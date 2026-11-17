# refpipe: reference databases for any marker (Kraken2 + Bracken + minimap2 for EPI2ME)

One config file, seven numbered scripts, and one Slurm script. Each marker gets its own output folder, so markers never mix.

## What you get
| Output (in `ref_<MARKER>/`) | Use |
|---|---|
| `epi2me_kraken2_<MARKER>/` (+ `.tar.gz`) | EPI2ME Kraken2 mode: `hash.k2d`, `opts.k2d`, `taxo.k2d`, `database*mers.kmer_distrib`, `taxdump/` |
| `epi2me_minimap2_<MARKER>/` (+ `.tar.gz`) | EPI2ME minimap2 mode: reference FASTA, `ref2taxid.tsv`, `taxdump/` |
| `kraken_db/` | The full database, for command-line Kraken2 and Bracken |
| `records.tsv`, `selected.tsv`, `taxid_fixes.tsv`, `failed_accessions.txt`, `self_test.kreport` | Records for your methods and the checks |

## Run it
```bash
acompile                                # compile node, not a login node
module load miniforge
bash 00_setup_envs.sh                   # checks and installs the environments if needed (names set in config.sh)
cp config.sh config_myMarker.sh        # optional: one config per marker
nano config.sh                          # edit MARKER, QUERY, MINLEN, MAXLEN, MAX_PER_TAXID, TAXONOMY_FROM
sbatch run_all.sbatch                   # all steps; or run the numbered scripts one by one
```
Run the scripts one at a time the first time, so you can check each stage. For a second marker, change `MARKER` (this changes `OUTDIR`) and rerun. To use a different config file: `CONFIG=config_myMarker.sh bash 01_fetch_records.sh`.

| Step | Environment | What it does | Check this before moving on |
|---|---|---|---|
| 00 | none (run on `acompile`) | Checks the `refbuild` and `kraken2` conda environments and the tools in them; creates or completes them if missing; reports whether `NCBI_API_KEY` is set | Ends with "All set." |
| 01 | refbuild | NCBI search; writes `records.tsv` and prints the length distribution | The count is plausible. Set `MINLEN` and `MAXLEN` from the length distribution |
| 02 | any | Keeps up to `MAX_PER_TAXID` per TaxID (longest first) | TaxID count is what you expected |
| 03 | refbuild | Downloads FASTA with `>ACC\|kraken:taxid\|TAXID` headers; safe to rerun | `failed_accessions.txt` is empty or small |
| 04 | kraken2 | Copies or downloads the taxonomy | Needs a `taxonomy/` folder with `nodes.dmp` |
| 05 | any | Remaps merged TaxIDs, drops deleted or unknown ones | `taxid_fixes.tsv`: how many dropped? |
| 06 | kraken2 | Builds Kraken2 and Bracken; self-test | `self_test.kreport` first line: unclassified should be near 0% |
| 07 | any | Builds the Kraken2 and minimap2 EPI2ME packages | Counts match; no duplicate names |

## Settings by marker type
| | Conserved gene (rbcL, matK) | Variable spacer (ndhF-rpl32, trnL-F, ITS2) |
|---|---|---|
| `QUERY` | `'(rbcL[Gene] OR rbcL[Title])'` | `'(ndhF[Title] AND (rpl32[Title] OR rpL32[Title]))'` (title wording varies; try variants and compare counts from step 01) |
| `MAX_PER_TAXID` | 1 | 3 |
| `MASKING` | yes | try both `yes` and `no` (separate `OUTDIR`s), compare the unclassified share |
| Length window | from step 01's distribution | wide at first (for example 400-2500), then narrow |

For a spacer you can also add amplicons cut from plastomes with in-silico PCR (see `Intergenic_Marker_Workflow_ndhF-rpl32.md`, stage 1b-1d). That is **not** automated here. Add those sequences to `OUTDIR/<MARKER>_by_taxid.fasta` with the same header format, then continue at step 04.

## Notes and limits
- Every step script also checks that its own tools are on the PATH and stops with a clear message if not (`lib.sh`). `run_all.sbatch` runs step 00 first.
- **Tested:** the file handling in steps 01-03, 05 and 07 against stand-in NCBI tools and a mock taxonomy (batch failure and fallback, resume, merged and unknown TaxIDs, ref2taxid and name checks). Step 00's logic (create, detect a missing tool, install, recheck, rerun with no changes, login-node guard) was tested against a stand-in `conda`, not a real install. Syntax of all scripts was checked.
- **Not tested:** real NCBI queries, `kraken2-build`, `bracken-build` and `--skip-maps`, `--use-ftp`, `--no-masking` on your Kraken2 version (confirm with `kraken2-build --help`), and the Slurm partition and QOS on Alpine.
- Taxonomy: use `TAXONOMY_FROM` to copy the same taxonomy used for earlier markers, so TaxIDs stay consistent across the class databases.
- Step 06 refuses to build into a folder whose library already has sequences, to prevent mixing markers.
- Bracken read lengths (`BRACKEN_LENGTHS`) should bracket your reads' median length. Check this after you know the new run's length distribution.
- NCBI API key: export `NCBI_API_KEY` in `~/.bashrc`. Do not put it in these scripts or in logs you share.
