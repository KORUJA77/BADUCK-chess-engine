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

[[nodiscard]] inline int ocbScaleFactorPct(const Board &board) {
    const int total_pieces = builtin::popcount(board.all());

    // Desativa scaling se h  pe as demais (n o   final puro)
    if (total_pieces > OCB_MAX_TOTAL_PIECES) return 100;

    const int passed = countPassedPawns(board, WHITE) + countPassedPawns(board, BLACK);
    int sf = OCB_PASSED_BASE + OCB_PASSED_MULT * passed;
    if (sf > OCB_SF_CAP) sf = OCB_SF_CAP;
    return (sf * 100) / OCB_SF_CAP;
}

[[nodiscard]] inline Score applyEndgameScaling(const Board &board, Score raw_score) {
    Score score = raw_score;

    if (FORTRESS_DETECT_WEIGHT > 0 && isInsufficientMaterial(board)) {
        score = score - (score * FORTRESS_DETECT_WEIGHT) / 100;
        return score;
    }

    if (OCB_SCALE_WEIGHT > 0 && isOppositeColoredBishops(board) && isPureOcbEndgame(board)) {
        // OCB scaling aplicado apenas quando score favorece as Brancas (score > 0)
        // Mantém agressividade das Brancas, freia superestimativa das Pretas
        if (score > 0) {
            // Brancas vencendo: sem scaling (deixa atacar)
        } else {
            const int scale_pct = ocbScaleFactorPct(board);
            const int effective_pct = 100 - ((100 - scale_pct) * OCB_SCALE_WEIGHT) / 100;
            score = static_cast<Score>((static_cast<int64_t>(score) * effective_pct) / 100);
        }
    }

    return score;
}

}  // namespace eval_scale
