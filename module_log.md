# BADUCK - Log de Modulos Experimentais

Criterio de decisao:
- Mantido: ganho de Elo >= +3 com LOS >= 95% em 1000+ partidas (8+0.08).
- Revertido: Elo neutro (-3 a +3) - modulo desativado (weight=0).
- Descartado: perda de Elo significativa - candidato a remocao.

---

## Modulo 1.1 - SPSA Painel de Parametros (tune.h)
- Status: Mantido (estrutural)
- Resultado: NPS baseline 1.313.000 -> 1.450.000 (+10%)
- Commit: aa1c4d8

---

## Modulo 2.3 - Compressao de Finais Estaticos (OCB / Fortress Scaling)
- Status: EXPERIMENTAL - validado funcionalmente, pendente teste de Elo
- Arquivos: eval_scale.h, evaluation.cpp
- Weight inicial: OCB_SCALE_WEIGHT=50, FORTRESS_DETECT_WEIGHT=50
- Validacao funcional: posicao FEN 8/5k2/8/3b4/8/2K5/3B4/8 w - - 0 1
  (bispos de cor oposta, material igual) convergiu para score cp 0 a
  partir da depth 5. Comportamento correto confirmado.
- NPS: 1.450.000 -> 1.471.000 (sem degradacao)
- Proximo passo: rodar run_spsa_test.sh comparando weight 0 vs 50 vs 100
- Resultado do torneio: (pendente)
- Decisao: (pendente)

---

## Modulo 1.2 - Gestao de Tempo (Time Management)
- Status: Nao iniciado

---

## Template para novos modulos
