#pragma once

// ============================================================
// BADUCK SPSA Tuning Parameters
// ============================================================
#ifdef TUNING
    #include <string>
    #include <vector>
    struct TuneParam {
        std::string name;
        int *value;
        int min, max, step;
    };
    inline std::vector<TuneParam> tuning_params;
    #define TUNE_PARAM(name, val, min, max, step) \
        inline int name = val; \
        inline bool name##_registered = (tuning_params.push_back({#name, &name, min, max, step}), true);
    #define MODULE_WEIGHT(name, val) \
        inline int name = val; \
        inline bool name##_registered = (tuning_params.push_back({#name, &name, 0, 100, 20}), true);
#else
    #define TUNE_PARAM(name, val, min, max, step) \
        inline int name = val;
    #define MODULE_WEIGHT(name, val) \
        inline int name = val;
#endif

TUNE_PARAM(LMR_BASE,        175,  100, 300, 10)
TUNE_PARAM(LMR_MIN_DEPTH,     3,    2,   5,  1)
TUNE_PARAM(LMR_MIN_MOVES,     3,    2,   6,  1)
TUNE_PARAM(RFP_MARGIN,       64,   30, 120, 10)
TUNE_PARAM(RFP_IMPROVING,    71,   30, 120, 10)
TUNE_PARAM(RFP_MAX_DEPTH,     6,    4,   9,  1)
TUNE_PARAM(RAZOR_MARGIN,    129,   60, 250, 15)
TUNE_PARAM(RAZOR_MAX_DEPTH,   3,    2,   5,  1)
TUNE_PARAM(NMP_BASE_R,        5,    3,   7,  1)
TUNE_PARAM(NMP_DEPTH_DIV,     5,    3,   8,  1)
TUNE_PARAM(NMP_EVAL_DIV,    214,  100, 400, 20)
TUNE_PARAM(NMP_MIN_DEPTH,     3,    2,   5,  1)
TUNE_PARAM(SE_BETA_MULT_WHITE,  3,    1,   6,  1)
TUNE_PARAM(SE_MIN_DEPTH_WHITE,  8,    5,  12,  1)
TUNE_PARAM(SE_TT_DEPTH_WHITE,   3,    1,   5,  1)
TUNE_PARAM(SE_BETA_MULT_BLACK,  1,   0,   6,  1)
TUNE_PARAM(SE_MIN_DEPTH_BLACK, 12,   5,  16,  1)
TUNE_PARAM(SE_TT_DEPTH_BLACK,   5,   0,   6,  1)
TUNE_PARAM(MULTICUT_REDUCTION_WHITE, 1, 0, 4, 1)
TUNE_PARAM(MULTICUT_REDUCTION_BLACK, 1,   0,   4,  1)
TUNE_PARAM(SEE_QUIET_MULT,   92,   40, 180, 10)
TUNE_PARAM(SEE_CAPT_MULT,    93,   40, 180, 10)
TUNE_PARAM(SEE_QUIET_DEPTH,   6,    3,   9,  1)
TUNE_PARAM(SEE_CAPT_DEPTH,    7,    3,   9,  1)
TUNE_PARAM(LMP_MAX_DEPTH,     5,    3,   8,  1)
TUNE_PARAM(LMP_BASE,          4,    2,   8,  1)

MODULE_WEIGHT(OCB_SCALE_WEIGHT, 41)
TUNE_PARAM(OCB_MAX_PAWNS_RELEVANT, 5, 2, 10, 1)
TUNE_PARAM(OCB_MAX_DIVISOR, 3, 2, 5, 1)
MODULE_WEIGHT(FORTRESS_DETECT_WEIGHT, 0)


// ============================================================
// MODULO 1.2 - Gestao de Tempo Dinamica (BADUCK Time Control)
// ============================================================
// Baseado em node-fraction (ideia Koivisto) + score-drop +
// best-move-instability ja presentes no Smallbrain. Aqui apenas
// expomos as constantes para tuning via SPSA.
TUNE_PARAM(TM_NODE_FRACTION_BASE,   110,   95, 130,  5)
TUNE_PARAM(TM_NODE_FRACTION_CAP,     90,   60, 100,  5)
TUNE_PARAM(TM_NODE_MIN_DEPTH,        10,    6,  14,  1)
TUNE_PARAM(TM_SCORE_RISING_MARGIN,   30,   10,  60,  5)
TUNE_PARAM(TM_EXTEND_PCT,           110,  100, 130,  5)
TUNE_PARAM(TM_SCORE_DROP_FLOOR,    -200, -400, -50, 25)
TUNE_PARAM(TM_SCORE_DROP_MARGIN,    -20,  -60,  -5,  5)
TUNE_PARAM(TM_INSTABILITY_LIMIT,      4,    2,   8,  1)
TUNE_PARAM(TM_INSTABILITY_PCT,       75,   50,  90,  5)
TUNE_PARAM(TM_HARDCAP_MIN_DEPTH,     10,    6,  14,  1)
TUNE_PARAM(TM_HARDCAP_NUM,           10,    8,  12,  1)
TUNE_PARAM(TM_HARDCAP_DEN,            6,    4,   8,  1)

// ============================================================
// MODULO 2.5 - Draw Bias Condicional (Pretas) - EXPERIMENTAL
// ============================================================
// Status: nao validado. Default = 0 (desligado).
MODULE_WEIGHT(BLACK_DRAW_BIAS_WEIGHT, 0)
TUNE_PARAM(BLACK_DRAW_BIAS_THRESHOLD, -50, -200, 0, 25)

// Modulo 2.3 v5/v6 - parametros ativos
TUNE_PARAM(OCB_MAX_TOTAL_PIECES, 8, 6, 14, 1)
TUNE_PARAM(OCB_PASSED_BASE, 18, 10, 30, 2)
TUNE_PARAM(OCB_PASSED_MULT,  4,  2,  8, 1)
TUNE_PARAM(OCB_SF_CAP,      64, 40, 80, 4)
