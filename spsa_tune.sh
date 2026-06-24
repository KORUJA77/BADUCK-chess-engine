#!/bin/bash
set -e

EXE="${1:?Uso: $0 <exe> <param_name> <start> <min> <max> <step> [iters] [games_per_iter]}"
PARAM="${2:?}"
VALUE="${3:?}"
PMIN="${4:?}"
PMAX="${5:?}"
STEP="${6:?}"
ITERS="${7:-20}"
GAMES_PER_ITER="${8:-20}"

OPENINGS="${OPENINGS_FILE:-./openings.epd}"
TC="${SPSA_TC:-1+0.01}"

if [ ! -f "$EXE" ]; then
    echo "ERRO: $EXE nao encontrado"
    exit 1
fi

echo "============================================================"
echo "SPSA Tuning - BADUCK"
echo "  Parametro: $PARAM"
echo "  Valor inicial: $VALUE (range [$PMIN, $PMAX], step inicial $STEP)"
echo "  Iteracoes: $ITERS | Jogos por iteracao: $GAMES_PER_ITER"
echo "============================================================"

CURRENT=$VALUE

for ((i=1; i<=ITERS; i++)); do
    DECAY=$(awk -v i="$i" -v n="$ITERS" -v s="$STEP" 'BEGIN { printf "%.2f", s * (1.0 - (i-1)/n)^2 }')
    CURRENT_STEP=$(awk -v d="$DECAY" 'BEGIN { v = int(d); if (v < 1) v = 1; print v }')

    PLUS=$(awk -v c="$CURRENT" -v s="$CURRENT_STEP" -v max="$PMAX" 'BEGIN { v = c + s; if (v > max) v = max; print v }')
    MINUS=$(awk -v c="$CURRENT" -v s="$CURRENT_STEP" -v min="$PMIN" 'BEGIN { v = c - s; if (v < min) v = min; print v }')

    echo ""
    echo "--- Iteracao $i/$ITERS --- step=$CURRENT_STEP  theta+=$PLUS  theta-=$MINUS"

    RESULT=$(cutechess-cli \
        -engine cmd="$EXE" name=Plus option.${PARAM}=${PLUS} \
        -engine cmd="$EXE" name=Minus option.${PARAM}=${MINUS} \
        -each proto=uci tc="$TC" option.Hash=16 option.Threads=1 \
        -games "$GAMES_PER_ITER" \
        -concurrency 2 \
        -repeat \
        -recover \
        -openings file="$OPENINGS" format=epd order=random \
        -ratinginterval 1 2>&1 | grep "Score of Plus vs Minus" | tail -1)

    echo "$RESULT"

    WLD=$(echo "$RESULT" | grep "Score of Plus vs Minus" | tail -1)
    WINS=$(echo "$WLD" | sed -n 's/.*: \([0-9]*\) - \([0-9]*\) - \([0-9]*\).*/\1/p')
    LOSSES=$(echo "$WLD" | sed -n 's/.*: \([0-9]*\) - \([0-9]*\) - \([0-9]*\).*/\2/p')

    if [ -z "$WINS" ] || [ -z "$LOSSES" ]; then
        echo "AVISO: nao consegui extrair resultado, mantendo valor atual"
        continue
    fi

    DIRECTION=$(awk -v w="$WINS" -v l="$LOSSES" 'BEGIN { print (w - l) }')
    NEW_CURRENT=$(awk -v c="$CURRENT" -v dir="$DIRECTION" -v s="$CURRENT_STEP" -v min="$PMIN" -v max="$PMAX" '
        BEGIN {
            delta = (dir > 0) ? s/4 : (dir < 0) ? -s/4 : 0
            v = c + delta
            if (v < min) v = min
            if (v > max) v = max
            printf "%.0f", v
        }')

    echo "Plus venceu $WINS, Minus venceu $LOSSES -> ajustando $CURRENT -> $NEW_CURRENT"
    CURRENT=$NEW_CURRENT
done

echo ""
echo "============================================================"
echo "RESULTADO FINAL"
echo "  $PARAM: $VALUE -> $CURRENT"
echo "============================================================"
echo ""
echo "Para aplicar este valor permanentemente, edite tune.h:"
echo "  TUNE_PARAM($PARAM, $CURRENT, $PMIN, $PMAX, ...)"
