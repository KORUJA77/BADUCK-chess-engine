#!/bin/bash
set -e

EXE="${1:?Uso: $0 <exe> <games_per_phase> [param nome valor_inicial min max] ...}"
GAMES="${2:-60}"
shift 2

declare -a PARAM_NAMES
declare -a PARAM_VALUES
declare -a PARAM_MINS
declare -a PARAM_MAXS

while [ $# -ge 4 ]; do
    PARAM_NAMES+=("$1")
    PARAM_VALUES+=("$2")
    PARAM_MINS+=("$3")
    PARAM_MAXS+=("$4")
    shift 4
done

N_PARAMS=${#PARAM_NAMES[@]}
OPENINGS="${OPENINGS_FILE:-./openings_balanced.epd}"
TC="${SPSA_TC:-1+0.01}"
CONCURRENCY="${SPSA_CONCURRENCY:-2}"

echo "============================================================"
echo "GRID SEARCH PROGRESSIVO (step proporcional) - BADUCK"
echo "  Engine: $EXE | TC: $TC | Jogos/combinacao: $GAMES | Concurrency: $CONCURRENCY"
for i in "${!PARAM_NAMES[@]}"; do
    echo "  ${PARAM_NAMES[$i]}: ${PARAM_VALUES[$i]} [${PARAM_MINS[$i]}, ${PARAM_MAXS[$i]}]"
done
echo "============================================================"

declare -a CUR_MINS
declare -a CUR_MAXS
declare -a BEST_VALS

for i in "${!PARAM_NAMES[@]}"; do
    CUR_MINS[$i]=${PARAM_MINS[$i]}
    CUR_MAXS[$i]=${PARAM_MAXS[$i]}
    BEST_VALS[$i]=${PARAM_VALUES[$i]}
done

BEST_GLOBAL_SCORE=-1
BEST_GLOBAL_COMBO=""
STATE_FILE="grid_state.txt"

if [ -f "$STATE_FILE" ]; then
    echo "Carregando checkpoint de $STATE_FILE..."
    source "$STATE_FILE"
    echo "  Melhor global: $BEST_GLOBAL_SCORE ($BEST_GLOBAL_COMBO)"
else
    echo "Nenhum estado anterior. Iniciando do zero."
fi

run_phase() {
    local PHASE_NAME="$1"
    local DIVISOR="$2"

    declare -a PHASE_STEPS
    local total=1
    for i in "${!PARAM_NAMES[@]}"; do
        local range=$((CUR_MAXS[$i] - CUR_MINS[$i]))
        local step=$(awk -v r="$range" -v d="$DIVISOR" 'BEGIN { s = int(r/d); if (s < 1) s = 1; print s }')
        PHASE_STEPS[$i]=$step
        local count=$(awk -v mn="${CUR_MINS[$i]}" -v mx="${CUR_MAXS[$i]}" -v s="$step" 'BEGIN { print int((mx - mn) / s) + 1 }')
        total=$((total * count))
    done

    echo ""
    echo "============================================================"
    echo "FASE: $PHASE_NAME | divisor=range/$DIVISOR | combinacoes=$total | jogos=$((total * GAMES))"
    echo "  Ranges e steps:"
    for i in "${!PARAM_NAMES[@]}"; do
        echo "    ${PARAM_NAMES[$i]}: [${CUR_MINS[$i]}, ${CUR_MAXS[$i]}] step=${PHASE_STEPS[$i]}"
    done
    echo "============================================================"

    COMBO_FILE=$(mktemp)

    generate_combos() {
        local depth=$1
        local current=$2
        if [ $depth -eq $N_PARAMS ]; then
            echo "$current" >> "$COMBO_FILE"
            return
        fi
        local v=${CUR_MINS[$depth]}
        local s=${PHASE_STEPS[$depth]}
        while [ $v -le ${CUR_MAXS[$depth]} ]; do
            generate_combos $((depth+1)) "$current ${PARAM_NAMES[$depth]}=$v"
            v=$((v + s))
        done
    }

    generate_combos 0 ""

    local BEST_SCORE=-1
    local BEST_COMBO=""
    local combo_num=0
    local total_combos=$(wc -l < "$COMBO_FILE")


    while IFS= read -r combo; do
        combo_num=$((combo_num + 1))

        TEST_OPTS=""
        COMBO_LABEL=""
        for pair in $combo; do
            name="${pair%%=*}"
            val="${pair##*=}"
            TEST_OPTS="$TEST_OPTS option.${name}=${val}"
            COMBO_LABEL="$COMBO_LABEL ${name}=${val}"
        done

        echo "--- $combo_num/$total_combos:$COMBO_LABEL ---"

        WLD=$(cutechess-cli             -engine cmd="$EXE" name=Test $TEST_OPTS             -engine cmd="${GRID_BASELINE:-./smallbrain_baseline.exe}" name=Base             -each proto=uci tc="$TC" option.Hash=16 option.Threads=1             -games "$GAMES" -concurrency "$CONCURRENCY" -repeat -recover             -openings file="$OPENINGS" format=epd order=random             -ratinginterval 1 2>&1 | grep "Score of Test vs Base" | tail -1)

        # Extrai W/L/D usando grep -oE para capturar todos os números
        NUMBERS=($(echo "$WLD" | grep -oE '[0-9]+'))
        WINS=${NUMBERS[0]}
        LOSSES=${NUMBERS[1]}
        DRAWS=${NUMBERS[2]}

        if [ -z "$WINS" ]; then
            echo "  AVISO: resultado invalido (WLD: $WLD)"
            continue
        fi

        SCORE=$(awk -v w="$WINS" -v l="$LOSSES" -v d="$DRAWS" 'BEGIN { printf "%.4f", (w + d*0.5) / (w + l + d) }')

        echo "  W=$WINS L=$LOSSES D=$DRAWS Score=$SCORE"

        BETTER=$(awk -v s="$SCORE" -v b="$BEST_SCORE" 'BEGIN { print (s > b) ? 1 : 0 }')
        if [ "$BETTER" -eq 1 ]; then
            BEST_SCORE=$SCORE
            BEST_COMBO="$combo"
            echo "  *** NOVO MELHOR DA FASE Score=$BEST_SCORE ***"
        fi

        BETTER_GLOBAL=$(awk -v s="$SCORE" -v b="$BEST_GLOBAL_SCORE" 'BEGIN { print (s > b) ? 1 : 0 }')
        if [ "$BETTER_GLOBAL" -eq 1 ]; then
            BEST_GLOBAL_SCORE=$SCORE
            BEST_GLOBAL_COMBO="$combo"
            echo "  *** NOVO MELHOR GLOBAL Score=$BEST_GLOBAL_SCORE ***"
        fi

    done < "$COMBO_FILE"
    rm -f "$COMBO_FILE"

    if [ -n "$BEST_GLOBAL_COMBO" ]; then
        echo "Atualizando ranges baseado no melhor global: $BEST_GLOBAL_COMBO"
        for pair in $BEST_GLOBAL_COMBO; do
            name="${pair%%=*}"
            val="${pair##*=}"
            for i in "${!PARAM_NAMES[@]}"; do
                if [ "${PARAM_NAMES[$i]}" = "$name" ]; then
                    BEST_VALS[$i]=$val
                    local s=${PHASE_STEPS[$i]}
                    NEW_MIN=$(awk -v v="$val" -v s="$s" -v mn="${PARAM_MINS[$i]}" 'BEGIN { r = v - 2*s; if (r < mn) r = mn; printf "%.0f", r }')
                    NEW_MAX=$(awk -v v="$val" -v s="$s" -v mx="${PARAM_MAXS[$i]}" 'BEGIN { r = v + 2*s; if (r > mx) r = mx; printf "%.0f", r }')
                    CUR_MINS[$i]=$NEW_MIN
                    CUR_MAXS[$i]=$NEW_MAX
                fi
            done
        done
    else
        echo "ATENCAO: Nenhum melhor global encontrado. Mantendo ranges atuais."
    fi

    echo "BEST_GLOBAL_SCORE=$BEST_GLOBAL_SCORE" > "$STATE_FILE"
    echo "BEST_GLOBAL_COMBO="$BEST_GLOBAL_COMBO"" >> "$STATE_FILE"
    for i in "${!PARAM_NAMES[@]}"; do
        echo "CUR_MINS[$i]=${CUR_MINS[$i]}" >> "$STATE_FILE"
        echo "CUR_MAXS[$i]=${CUR_MAXS[$i]}" >> "$STATE_FILE"
        echo "BEST_VALS[$i]=${BEST_VALS[$i]}" >> "$STATE_FILE"
    done

    echo ""
    echo "Melhor global ate agora: Score=$BEST_GLOBAL_SCORE"
    echo "  $BEST_GLOBAL_COMBO"
    echo "Proximos ranges:"
    for i in "${!PARAM_NAMES[@]}"; do
        echo "  ${PARAM_NAMES[$i]}: [${CUR_MINS[$i]}, ${CUR_MAXS[$i]}]"
    done
}

run_phase "EXPLORACAO"  4
run_phase "REFINAMENTO" 8
run_phase "AJUSTE_FINO" 16
run_phase "PRECISAO"    32

echo ""
echo "============================================================"
echo "RESULTADO FINAL"
echo "  Melhor global: Score=$BEST_GLOBAL_SCORE"
for i in "${!PARAM_NAMES[@]}"; do
    echo "  ${PARAM_NAMES[$i]}: ${BEST_VALS[$i]}"
done
echo "============================================================"
echo "Para aplicar, edite tune.h com os valores acima."
echo "Checkpoint salvo em $STATE_FILE (pode reiniciar se interrompido)"
