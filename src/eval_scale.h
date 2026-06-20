#pragma once

// ============================================================
// BADUCK - Modulo 2.3: Compressao de Finais Estaticos
// ============================================================
#include "board.h"
#include "builtin.h"
#include "tune.h"
#include "types.h"

namespace eval_scale {

constexpr Bitboard LIGHT_SQUARES = 0x55AA55AA55AA55AAULL;

[[nodiscard]] constexpr bool isLightSquare(Square sq) {
    return (LIGHT_SQUARES >> sq) & 1ULL;
}

[[nodiscard]] inline bool isOppositeColoredBishops(const Board &board) {
    const Bitboard white_bishops = board.pieces(BISHOP, WHITE);
    const Bitboard black_bishops = board.pieces(BISHOP, BLACK);

    if (builtin::popcount(white_bishops) != 1 || builtin::popcount(black_bishops) != 1) {
        return false;
    }

    const Square white_sq = builtin::lsb(white_bishops);
    const Square black_sq = builtin::lsb(black_bishops);

    return isLightSquare(white_sq) != isLightSquare(black_sq);
}

[[nodiscard]] inline bool isPureOcbEndgame(const Board &board) {
    const Bitboard major_minor =
        board.pieces(KNIGHT) | board.pieces(ROOK) | board.pieces(QUEEN);
    return major_minor == 0ULL;
}

[[nodiscard]] inline bool isInsufficientMaterial(const Board &board) {
    const Bitboard heavy =
        board.pieces(PAWN) | board.pieces(ROOK) | board.pieces(QUEEN);
    if (heavy != 0ULL) return false;

    const int white_minors =
        builtin::popcount(board.pieces(KNIGHT, WHITE) | board.pieces(BISHOP, WHITE));
    const int black_minors =
        builtin::popcount(board.pieces(KNIGHT, BLACK) | board.pieces(BISHOP, BLACK));

    return white_minors <= 1 && black_minors <= 1 && (white_minors + black_minors) <= 1;
}

[[nodiscard]] inline Score applyEndgameScaling(const Board &board, Score raw_score) {
    const int total_pawns = builtin::popcount(board.pieces(PAWN));
    if (total_pawns > OCB_MAX_PAWNS_RELEVANT &&
        builtin::popcount(board.all()) > 10) {
        return raw_score;
    }

    Score score = raw_score;

    if (FORTRESS_DETECT_WEIGHT > 0 && isInsufficientMaterial(board)) {
        score = score - (score * FORTRESS_DETECT_WEIGHT) / 100;
        return score;
    }

    if (OCB_SCALE_WEIGHT > 0 && isOppositeColoredBishops(board) && isPureOcbEndgame(board)) {
        const int divisor_num = 100 + (OCB_MAX_DIVISOR - 1) * OCB_SCALE_WEIGHT;
        score = static_cast<Score>((static_cast<int64_t>(score) * 100) / divisor_num);
    }

    return score;
}

}  // namespace eval_scale
