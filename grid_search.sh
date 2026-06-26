#!/bin/bash
set -e

EXE="${1:?Uso: $0 <exe> <games> <step> [param nome valor_inicial min max] ...}"
GAMES="${2:-100}"
STEP="${3:-2}"
shift 3

declare -a PARAM_NAMES
declare -a PARAM_DEFAULTS
declare -a PARAM_MINS
declare -a PARAM_MAXS

while [ $# -ge 4 ]; do
    PARAM_NAMES+=("$1")
    PARAM_DEFAULTS+=("$2")
    PARAM_MINS+=("$3")
    PARAM_MAXS+=("$4")
    shift 4
done

N_PARAMS=${#PARAM_NAMES[@]}
OPENINGS="${OPENINGS_FILE:-./openings_balanced.epd}"
TC="${SPSA_TC:-1+0.01}"

# Gera todos os valores possiveis por parametro
declare -a ALL_VALUES
for i in "${!PARAM_NAMES[@]}"; do
    vals=""
    v=${PARAM_MINS[$i]}
    while [ $v -le ${PARAM_MAXS[$i]} ]; do
        vals="$vals $v"
        v=$((v + STEP))
    done
    ALL_VALUES[$i]="$vals"
done

# Conta combinacoes
total=1
for i in "${!PARAM_NAMES[@]}"; do
    count=$(echo ${ALL_VALUES[$i]} | wc -w)
    total=$((total * count))
done

echo "============================================================"
echo "GRID SEARCH - BADUCK"
echo "  Engine: $EXE | TC: $TC | Jogos/combinacao: $GAMES | Step: $STEP"
echo "  Parametros: $N_PARAMS | Combinacoes: $total"
echo "  Jogos totais estimados: $((total * GAMES))"
for i in "${!PARAM_NAMES[@]}"; do
    echo "  ${PARAM_NAMES[$i]}: [${PARAM_MINS[$i]}, ${PARAM_MAXS[$i]}] step=$STEP"
done
echo "============================================================"

BEST_SCORE=-1
BEST_COMBO=""
combo_num=0

# Referencia: engine com valores default vs si mesma
DEFAULT_OPTS=""
for i in "${!PARAM_NAMES[@]}"; do
    DEFAULT_OPTS="$DEFAULT_OPTS option.${PARAM_NAMES[$i]}=${PARAM_DEFAULTS[$i]}"
done

# Funcao recursiva simulada via arquivo temporario de combinacoes
COMBO_FILE=$(mktemp)

generate_combos() {
    local depth=$1
    local current=$2

    if [ $depth -eq $N_PARAMS ]; then
        echo "$current" >> "$COMBO_FILE"
        return
    fi

    for v in ${ALL_VALUES[$depth]}; do
        generate_combos $((depth+1)) "$current ${PARAM_NAMES[$depth]}=$v"
    done
}

generate_combos 0 ""

total_combos=$(wc -l < "$COMBO_FILE")
echo "Combinacoes geradas: $total_combos"
echo ""

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

    echo "--- Combo $combo_num/$total_combos:$COMBO_LABEL ---"

    WLD=$(cutechess-cli         -engine cmd="$EXE" name=Test $TEST_OPTS         -engine cmd="$EXE" name=Base $DEFAULT_OPTS         -each proto=uci tc="$TC" option.Hash=16 option.Threads=1         -games "$GAMES" -concurrency 2 -repeat -recover         -openings file="$OPENINGS" format=epd order=random         -ratinginterval 1 2>&1 | grep "Score of Test vs Base" | tail -1)

    WINS=$(echo "$WLD" | sed -n "s/.*: \([0-9]*\) - \([0-9]*\) - \([0-9]*\).*//p")
    LOSSES=$(echo "$WLD" | sed -n "s/.*: \([0-9]*\) - \([0-9]*\) - \([0-9]*\).*//p")
    DRAWS=$(echo "$WLD" | sed -n "s/.*: \([0-9]*\) - \([0-9]*\) - \([0-9]*\).*//p")

    if [ -z "$WINS" ]; then
        echo "  AVISO: resultado invalido"
        continue
    fi

    SCORE=$(awk -v w="$WINS" -v l="$LOSSES" -v d="$DRAWS"         "BEGIN { printf "%.4f", (w + d*0.5) / (w + l + d) }")

    echo "  W=$WINS L=$LOSSES D=$DRAWS Score=$SCORE"

    BETTER=$(awk -v s="$SCORE" -v b="$BEST_SCORE" "BEGIN { print (s > b) ? 1 : 0 }")
    if [ "$BETTER" -eq 1 ]; then
        BEST_SCORE=$SCORE
        BEST_COMBO="$COMBO_LABEL"
        echo "  *** NOVO MELHOR: Score=$BEST_SCORE ***"
    fi

done < "$COMBO_FILE"

rm -f "$COMBO_FILE"

echo ""
echo "============================================================"
echo "RESULTADO FINAL"
echo "  Melhor combinacao:$BEST_COMBO"
echo "  Score vs default: $BEST_SCORE"
echo "============================================================"
