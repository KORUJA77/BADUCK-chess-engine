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

---

## Modulo 1.2 - Gestao de Tempo Dinamica (BADUCK Time Control)
- Status: Mantido (estrutural - parametrizacao de mecanismo ja existente)
- Arquivos: tune.h, search.cpp
- Abordagem: o Smallbrain ja possuia node-fraction (estilo Koivisto) +
  score-drop detection + best-move-instability. Decisao tecnica: nao
  reescrever do zero com "annealing simulado" (sem precedente validado
  na literatura), e sim parametrizar via TUNE_PARAM o mecanismo
  existente e comprovado, mantendo identidade BADUCK no naming.
- Validacao funcional: go wtime 10000 btime 10000 winc 100 binc 100
  na posicao inicial - aprofundou ate depth 17 com tempo gerenciado
  de forma coerente e parada natural.
- Proximo passo: SPSA tuning dos parametros TM_* via torneio.
- Resultado do torneio: (pendente)
- Decisao: (pendente)

---

## Modulo 2.4 - Sistema Completo de Reconhecimento de Finais
### (baseado em ESTUDO_PARA_EMPATES.docx)

- **Status:** Planejado - aguardando implementacao
- **Origem:** documento de estudo do usuario, cobre 13 categorias de
  padroes de empate/scale factor, com hierarquia de confianca proposta:
  Tablebases (EGTB) > Interior Node Recognizers (INR) > Scale Factors
  na avaliacao.
- **Decisao de escopo:** o documento e tecnicamente solido, mas nem
  todo item tem o mesmo ROI. Ordem de implementacao definida por
  custo vs impacto real medido (nao por ordem do documento):

### Fila de prioridade

1. **NMP zugzwang-safe** (correcao de busca, nao scale factor)
   - Problema: Null Move Pruning falha em finais de zugzwang mutuo
     (KPK, finais bloqueados). Pode gerar avaliacoes erradas mesmo
     em posicoes de vantagem clara, nao so em empates.
   - Prioridade MAXIMA: e bug de correcao, nao feature de empate.
   - Custo: baixo (condicional simples antes do NMP).

2. **Formula OCB correta do Stockfish**
   - Substituir nosso divisor fixo (OCB_MAX_DIVISOR) pela formula
     sf = 18 + 4 * (numero de peoes passados).
   - Custo: baixo. Ja temos a deteccao de OCB pronta (Modulo 2.3).

3. **Bispo errado + peao de torre (Wrong Rook Pawn)**
   - Peao em coluna a/h, bispo do lado forte nao controla a casa
     de promocao, rei defensor no canto -> Score = 0.
   - Custo: medio. Padrao classico, bem documentado.

4. **KPK - Regra do Quadrado**
   - Custo: medio-baixo. Calculo geometrico direto (manhattan
     distance vs distancia do rei defensor).

5. **Finais de Torre - Philidor e Vancura**
   - Maior valor pratico (finais de torre sao os mais comuns em
     jogo real), mas maior custo de implementacao.

6. **Demais itens do documento** (Troitzky, fortalezas de dama,
   KR vs KN/KB, complexity reduction) - prioridade baixa, ROI
   incerto para frequencia de ocorrencia em jogo pratico.

### Ressalvas tecnicas (divergencias do documento original)

- **KR vs KN/KB tratado como "empate estatico" no documento original
  e PERIGOSO sem ajuste.** Torre vs peca menor sem peoes e dificil
  de converter mas NAO e fortress absoluta (~50% das posicoes
  aleatorias sao teoricamente ganhas para o lado da torre). Decisao:
  implementar como scale factor reduzido (~30-40%), nunca como
  score=0 fixo, para nao desistir de posicoes genuinamente vencedoras.

- **Linha de Troitzky**: alta complexidade de implementacao para
  frequencia muito baixa em partidas reais. Rebaixado para ultima
  prioridade.

- **NMP zugzwang**: promovido do item 13 (quase ultimo no documento)
  para prioridade 1 nesta lista, por ser correcao de busca geral e
  nao apenas reconhecimento de empate.

### Proximo passo

Implementar item 1 (NMP zugzwang-safe) e item 2 (formula OCB correta)
primeiro, validar funcionalmente, medir Elo, so entao avancar para os
itens de maior custo (3-5).

- **Resultado:** (pendente)
- **Decisao:** (pendente)
