#!/usr/bin/env python3
"""Check TaxIDs in a kraken-style FASTA against a taxonomy folder.
Keeps valid IDs, remaps merged IDs (merged.dmp), drops IDs that are deleted or unknown.
Usage: fix_taxids.py taxonomy_dir in.fasta out.fasta report.tsv"""
import sys, os, re
tax, fin, fout, rep = sys.argv[1:5]
def ids(fn, col=0):
    s = set()
    if os.path.exists(fn):
        for l in open(fn):
            s.add(l.split("|")[col].strip())
    return s
have = ids(os.path.join(tax, "nodes.dmp"))
if not have:
    sys.exit("nodes.dmp not found or empty in " + tax)
merged = {}
fn = os.path.join(tax, "merged.dmp")
if os.path.exists(fn):
    for l in open(fn):
        p = [x.strip() for x in l.split("|")]
        merged[p[0]] = p[1]
n = {"ok": 0, "remapped": 0, "dropped": 0}
keep = False
with open(fin) as f, open(fout, "w") as o, open(rep, "w") as r:
    r.write("accession\told_taxid\taction\tnew_taxid\n")
    for line in f:
        if line.startswith(">"):
            m = re.match(r">(\S+?)\|kraken:taxid\|(\d+)(.*)", line.rstrip("\n"))
            if not m:
                keep = False; n["dropped"] += 1
                r.write(f"{line[1:].split()[0]}\t?\tdropped (bad header)\t\n"); continue
            acc, t, rest = m.groups()
            if t in have:
                n["ok"] += 1; keep = True; o.write(line)
            elif t in merged and merged[t] in have:
                n["remapped"] += 1; keep = True
                o.write(f">{acc}|kraken:taxid|{merged[t]}{rest}\n"); r.write(f"{acc}\t{t}\tremapped\t{merged[t]}\n")
            else:
                n["dropped"] += 1; keep = False; r.write(f"{acc}\t{t}\tdropped\t\n")
        elif keep:
            o.write(line)
print(f"TaxIDs ok: {n['ok']}  remapped: {n['remapped']}  dropped: {n['dropped']}  (details: {rep})")
