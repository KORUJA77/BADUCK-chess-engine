#!/bin/bash
set -e

EXE="${1:?Uso: $0 <exe> <\"fen ou startpos\"> <go_args>}"
POSITION="${2:-startpos}"
GO_ARGS="${3:-depth 16}"

if [ ! -f "$EXE" ]; then
    echo "ERRO: $EXE nao encontrado"
    exit 1
fi

TMPFILE=$(mktemp)

if [ "$POSITION" = "startpos" ]; then
    POS_CMD="position startpos"
else
    POS_CMD="position $POSITION"
fi

(printf "%s\ngo %s\n" "$POS_CMD" "$GO_ARGS"; sleep 30; printf "quit\n") | "$EXE" > "$TMPFILE"

echo "============================================================"
echo "EBF Calculator - BADUCK"
echo "  Posicao: $POSITION"
echo "  Go args: $GO_ARGS"
echo "============================================================"

awk '
/^info depth/ {
    depth = 0; nodes = 0
    for (i = 1; i <= NF; i++) {
        if ($i == "depth") depth = $(i+1)
        if ($i == "nodes") nodes = $(i+1)
    }
    if (depth > 0 && nodes > 0) {
        d[depth] = nodes
        maxd = depth
    }
}
END {
    print "Depth\tNodes\t\tEBF"
    prev = 0
    sum = 0
    sum2 = 0
    cnt = 0
    cnt2 = 0
    half = maxd / 2
    for (i = 1; i <= maxd; i++) {
        if (i in d) {
            if (prev > 0) {
                ebf = d[i] / prev
                printf "%d\t%d\t\t%.3f\n", i, d[i], ebf
                sum += ebf
                cnt++
                if (i > half) {
                    sum2 += ebf
                    cnt2++
                }
            } else {
                printf "%d\t%d\t\t--\n", i, d[i]
            }
            prev = d[i]
        }
    }
    print "------------------------------------------------------------"
    if (cnt > 0) printf "EBF medio (todas profundidades):     %.3f\n", sum/cnt
    if (cnt2 > 0) printf "EBF medio (segunda metade, estavel): %.3f\n", sum2/cnt2
    print "------------------------------------------------------------"
    print "Referencia: motores de elite ficam tipicamente entre 1.4-1.8."
}
' "$TMPFILE"

rm -f "$TMPFILE"
