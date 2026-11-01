"""Fusionne des rulesets Zircolite JSON.

Le premier fichier est prioritaire et gardé en entier (doublons exacts id+SQL retirés).
Pour les suivants, une règle est ignorée si son id figure déjà dans le premier fichier
ou si le couple (id, SQL) a déjà été vu.
"""
import json
import os
import sys


def load(path):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    if isinstance(data, list):
        return None, data
    return data, data.get("rules", [])


def sql_key(rule):
    return json.dumps(rule.get("sigma") or rule.get("rule"), sort_keys=True)


out, inputs = sys.argv[1], sys.argv[2:]
wrapper, merged = None, []
seen, base_ids = set(), set()
for path in inputs:
    if not os.path.exists(path):
        print(f"[!] absent : {path}")
        continue
    meta, rules = load(path)
    if not merged and meta is not None:
        wrapper = meta
    first = not merged
    kept = 0
    for r in rules:
        key = (r.get("id") or r.get("title"), sql_key(r))
        if key in seen or (not first and key[0] in base_ids):
            continue
        seen.add(key)
        merged.append(r)
        kept += 1
        if first:
            base_ids.add(key[0])
    print(f"[+] {path}: {len(rules)} règles, {kept} retenues")

if wrapper is not None:
    wrapper["rules"] = merged
    merged = wrapper
with open(out, "w", encoding="utf-8") as f:
    json.dump(merged, f, ensure_ascii=False)
print(f"[+] {out}: {len(merged['rules'] if isinstance(merged, dict) else merged)} règles")
