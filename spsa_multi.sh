#!/bin/bash
set -e

EXE="${1:?Uso: $0 <exe> <games_per_iter> [param nome valor min max] ...}"
GAMES_PER_ITER="${2:-40}"
shift 2

declare -a PARAM_NAMES
declare -a PARAM_VALUES
declare -a PARAM_MINS
declare -a PARAM_MAXS

while [ $# -ge 5 ]; do
    PARAM_NAMES+=("$1")
    PARAM_VALUES+=("$2")
    PARAM_MINS+=("$3")
    PARAM_MAXS+=("$4")
    shift 4
done

N_PARAMS=${#PARAM_NAMES[@]}
OPENINGS="${OPENINGS_FILE:-./openings_balanced.epd}"
TC="${SPSA_TC:-1+0.01}"

echo "============================================================"
echo "SPSA Multi-Parametro (gradiente independente) - BADUCK"
echo "  Engine: $EXE | TC: $TC | Jogos/iter por param: $GAMES_PER_ITER"
for i in "${!PARAM_NAMES[@]}"; do
    echo "  ${PARAM_NAMES[$i]}: ${PARAM_VALUES[$i]} [${PARAM_MINS[$i]}, ${PARAM_MAXS[$i]}]"
done
echo "============================================================"

run_phase() {
    local PHASE_NAME="$1"
    local STEP="$2"
    local ITERS="$3"

    echo ""
    echo "============================================================"
    echo "FASE: $PHASE_NAME | step=$STEP | iteracoes=$ITERS"
    echo "============================================================"

    for ((iter=1; iter<=ITERS; iter++)); do
        echo ""
        echo "--- Iter $iter/$ITERS (step=$STEP) ---"

        # Para cada parametro: pertuba independentemente, roda jogo proprio
        for i in "${!PARAM_NAMES[@]}"; do
            # Valores base para todos os parametros (sem perturbacao)
            BASE_OPTS=""
            for j in "${!PARAM_NAMES[@]}"; do
                BASE_OPTS="$BASE_OPTS option.${PARAM_NAMES[$j]}=${PARAM_VALUES[$j]}"
            done

            PLUS=$(awk -v v="${PARAM_VALUES[$i]}" -v s="$STEP" -v mx="${PARAM_MAXS[$i]}"                 'BEGIN { r = v + s; if (r > mx) r = mx; printf "%.0f", r }')
            MINUS=$(awk -v v="${PARAM_VALUES[$i]}" -v s="$STEP" -v mn="${PARAM_MINS[$i]}"                 'BEGIN { r = v - s; if (r < mn) r = mn; printf "%.0f", r }')

            # Substitui só o parametro i nos opts
            PLUS_OPTS=$(echo "$BASE_OPTS" | sed "s/option.${PARAM_NAMES[$i]}=[^ ]*/option.${PARAM_NAMES[$i]}=${PLUS}/")
            MINUS_OPTS=$(echo "$BASE_OPTS" | sed "s/option.${PARAM_NAMES[$i]}=[^ ]*/option.${PARAM_NAMES[$i]}=${MINUS}/")

            WLD=$(cutechess-cli                 -engine cmd="$EXE" name=Plus $PLUS_OPTS                 -engine cmd="$EXE" name=Minus $MINUS_OPTS                 -each proto=uci tc="$TC" option.Hash=16 option.Threads=1                 -games "$GAMES_PER_ITER" -concurrency 2 -repeat -recover                 -openings file="$OPENINGS" format=epd order=random                 -ratinginterval 1 2>&1 | grep "Score of Plus vs Minus" | tail -1)

            WINS=$(echo "$WLD" | sed -n 's/.*: \([0-9]*\) - \([0-9]*\) - \([0-9]*\).*//p')
            LOSSES=$(echo "$WLD" | sed -n 's/.*: \([0-9]*\) - \([0-9]*\) - \([0-9]*\).*//p')

            if [ -z "$WINS" ] || [ -z "$LOSSES" ]; then
                echo "  ${PARAM_NAMES[$i]}: AVISO resultado invalido, mantendo ${PARAM_VALUES[$i]}"
                continue
            fi

            NEW=$(awk -v v="${PARAM_VALUES[$i]}" -v s="$STEP" -v w="$WINS" -v l="$LOSSES"                       -v mn="${PARAM_MINS[$i]}" -v mx="${PARAM_MAXS[$i]}"                 'BEGIN {
                    grad = (w > l) ? 1 : (w < l) ? -1 : 0
                    delta = s/4 * grad
                    r = v + delta
                    if (r < mn) r = mn
                    if (r > mx) r = mx
                    printf "%.0f", r
                }')

            echo "  ${PARAM_NAMES[$i]}: ${PARAM_VALUES[$i]} -> $NEW  [+=${PLUS} -=${MINUS} W=$WINS L=$LOSSES]"
            PARAM_VALUES[$i]=$NEW
        done
    done
}

run_phase "EXPLORACAO" 10 45
run_phase "REFINAMENTO" 5  45
run_phase "PRECISAO"    1  45

echo ""
echo "============================================================"
echo "RESULTADO FINAL"
for i in "${!PARAM_NAMES[@]}"; do
    echo "  ${PARAM_NAMES[$i]}: ${PARAM_VALUES[$i]}"
done
echo "============================================================"
echo "Para aplicar, edite tune.h com os valores acima."
