#pragma once

// ============================================================
// BADUCK - Modulo 2.5: Draw Bias Condicional (Pretas)
// ============================================================
// HIPOTESE A TESTAR (nao comprovada ainda):
//   Weight 0 = desligado (default). So deve ser ligado depois de
//   confirmar com amostra estatistica robusta (300-500+ partidas)
//   que o desequilibrio de resultado por cor e real e nao ruido.
//
// Aplicado SOMENTE no eval, nunca na comparacao interna do
// alpha-beta, para preservar corretude da poda.
// ============================================================

#include "board.h"
#include "tune.h"
#include "types.h"

namespace draw_bias {

[[nodiscard]] inline Score applyBlackDrawBias(const Board &board, Score raw_score) {
    if (BLACK_DRAW_BIAS_WEIGHT == 0) return raw_score;

    if (board.sideToMove() != BLACK) return raw_score;

    if (raw_score >= BLACK_DRAW_BIAS_THRESHOLD) return raw_score;

    if (raw_score <= VALUE_MATED_IN_PLY + MAX_PLY || raw_score >= VALUE_MATE_IN_PLY - MAX_PLY) {
        return raw_score;
    }

    Score adjusted = raw_score + (-raw_score * BLACK_DRAW_BIAS_WEIGHT) / 200;

    return adjusted;
}

}  // namespace draw_bias
