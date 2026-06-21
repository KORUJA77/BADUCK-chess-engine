#pragma once

#include "board.h"
#include "builtin.h"
#include "tune.h"
#include "types.h"

namespace eval_scale {

constexpr Bitboard LIGHT_SQUARES = 0x55AA55AA55AA55AAULL;
constexpr Bitboard FILE_A = 0x0101010101010101ULL;

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

[[nodiscard]] inline Bitboard frontSpanMask(Square sq, Color c) {
    const int file = sq % 8;
    const int rank = sq / 8;

    Bitboard files = FILE_A << file;
    if (file > 0) files |= FILE_A << (file - 1);
    if (file < 7) files |= FILE_A << (file + 1);

    if (c == WHITE) {
        Bitboard ranks_ahead = ~0ULL << ((rank + 1) * 8);
        return files & ranks_ahead;
    } else {
        Bitboard ranks_ahead = (1ULL << (rank * 8)) - 1ULL;
        return files & ranks_ahead;
    }
}

[[nodiscard]] inline int countPassedPawns(const Board &board, Color c) {
    Bitboard our_pawns = board.pieces(PAWN, c);
    Bitboard enemy_pawns = board.pieces(PAWN, ~c);

    int count = 0;
    while (our_pawns) {
        Square sq = builtin::lsb(our_pawns);
        our_pawns &= our_pawns - 1;

        if ((frontSpanMask(sq, c) & enemy_pawns) == 0ULL) {
            count++;
        }
    }
    return count;
}

[[nodiscard]] inline int pawnDampeningPct(int total_pawns) {
    if (total_pawns <= OCB_DAMPEN_START_PAWNS) return 100;

    int excess = total_pawns - OCB_DAMPEN_START_PAWNS;
    int dampening = 100 - excess * OCB_DAMPEN_PER_PAWN;

    if (dampening < OCB_DAMPEN_FLOOR_PCT) dampening = OCB_DAMPEN_FLOOR_PCT;
    return dampening;
}

[[nodiscard]] inline int phaseDampeningPct(int total_pieces) {
    if (total_pieces <= OCB_DAMPEN_START_PIECES) return 100;

    int excess = total_pieces - OCB_DAMPEN_START_PIECES;
    int dampening = 100 - excess * OCB_DAMPEN_PER_PIECE;

    if (dampening < OCB_DAMPEN_FLOOR_PCT) dampening = OCB_DAMPEN_FLOOR_PCT;
    return dampening;
}

[[nodiscard]] inline int ocbScaleFactorPct(const Board &board) {
    const int passed = countPassedPawns(board, WHITE) + countPassedPawns(board, BLACK);
    const int total_pawns = builtin::popcount(board.pieces(PAWN));
    const int total_pieces = builtin::popcount(board.all());

    int sf = 18 + 4 * passed;
    if (sf > 64) sf = 64;
    int base_pct = (sf * 100) / 64;

    const int pawn_damp = pawnDampeningPct(total_pawns);
    const int phase_damp = phaseDampeningPct(total_pieces);

    int effective = 100 - ((100 - base_pct) * pawn_damp * phase_damp) / 10000;

    return effective;
}

[[nodiscard]] inline Score applyEndgameScaling(const Board &board, Score raw_score) {
    Score score = raw_score;

    if (FORTRESS_DETECT_WEIGHT > 0 && isInsufficientMaterial(board)) {
        score = score - (score * FORTRESS_DETECT_WEIGHT) / 100;
        return score;
    }

    if (OCB_SCALE_WEIGHT > 0 && isOppositeColoredBishops(board) && isPureOcbEndgame(board)) {
        const int scale_pct = ocbScaleFactorPct(board);
        const int effective_pct = 100 - ((100 - scale_pct) * OCB_SCALE_WEIGHT) / 100;
        score = static_cast<Score>((static_cast<int64_t>(score) * effective_pct) / 100);
    }

    return score;
}

}  // namespace eval_scale
