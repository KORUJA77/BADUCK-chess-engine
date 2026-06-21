#include <algorithm>  // clamp
#include "evaluation.h"
#include "eval_scale.h"
#include "draw_bias.h"
#include "nnue.h"

namespace eval {
Score evaluate(Board &board) {
    int32_t v = nnue::output(board.getAccumulator(), board.sideToMove());
    v = static_cast<double>(v) * (1.0 - (board.halfmoves() / 1000.0));

    Score score = std::clamp(static_cast<int>(v), (int32_t)(VALUE_MATED_IN_PLY + 1),
                             (int32_t)(VALUE_MATE_IN_PLY - 1));

    score = eval_scale::applyEndgameScaling(board, score);
    score = draw_bias::applyBlackDrawBias(board, score);

    return score;
}
}  // namespace eval
