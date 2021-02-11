#!/bin/sh
set -euC
cd "$(dirname "$0")"

ref_ppx=
other_ppxes=
for ppx in ppx_nop/ppx_nop_*.ml; do
    ppx=${ppx#ppx_nop/ppx_nop_}
    ppx=${ppx%.ml}
    if [ -z "$ref_ppx" ]; then
        ref_ppx=$ppx
    else
        other_ppxes="$other_ppxes $ppx"
    fi
done

files=
for file in *.ml; do
    file=${file%.ml}
    files="$files $file"
done

## All comparisons

printf '(rule\n (alias runtest)\n (action\n  (progn'

for file in $files; do
    printf '\n'
    for other_ppx in $other_ppxes; do
        printf '   (diff %s_%s.expected %s_%s.expected)\n' \
               "$file" "$ref_ppx" "$file" "$other_ppx"
    done
done

printf ')))\n'

## All generations

for ppx in $ref_ppx $other_ppxes; do
    printf '\n;; ppx_nop_%s\n' "$ppx"

    for file in $files; do
        printf '\n'
        printf '(rule (action (copy %s.ml %s_%s.ml)))\n' \
               "$file" "$file" "$ppx"
        printf '(executable (name %s_%s) (modules %s_%s) (preprocess (pps ppx_nop_%s)))\n' \
               "$file" "$ppx" "$file" "$ppx" "$ppx"
        printf '(rule (with-stdout-to %s_%s.expected (run ./%s_%s.exe)))\n' \
               "$file" "$ppx" "$file" "$ppx"
    done
done
