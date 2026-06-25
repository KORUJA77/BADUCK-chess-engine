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

---

## Modulo 2.5 - Draw Bias Condicional (Pretas)

- Status: EXPERIMENTAL - implementado, DESLIGADO por padrao (weight=0)
- Arquivos: draw_bias.h, tune.h, evaluation.cpp
- Hipotese a validar: jogando de pretas, abaixo de um threshold de
  desvantagem (BLACK_DRAW_BIAS_THRESHOLD), reduzir a magnitude do
  score pode favorecer linhas mais solidas e reduzir taxa de derrota,
  sem reduzir proporcionalmente mais a taxa de vitoria.
- Design tecnico: aplicado SOMENTE no valor de retorno do eval, nunca
  na comparacao interna do alpha-beta (preserva corretude da poda).
- Origem do experimento: torneio de 40 partidas (commit 836d89f)
  mostrou BADUCK 5-0-15 de brancas vs 1-6-13 de pretas contra
  Smallbrain baseline. Amostra pequena demais para confirmar padrao
  real vs ruido estatistico.
- Pre-requisito antes de ligar o weight: rodar 300-500 partidas SEM
  draw bias (weight=0) para confirmar se o desequilibrio de cor
  persiste em amostra maior. So entao faz sentido testar weight > 0.
- NPS: sem impacto (1.451.000, identico ao Modulo 1.2)
- Resultado do torneio: (pendente - aguardando amostra maior primeiro)
- Decisao: (pendente)

---

## Modulo 1.3 - PGO (Profile-Guided Optimization)

- Status: Mantido (otimizacao de build, sem mudanca de logica)
- Arquivos: Makefile (removida duplicacao de target pgo, usado o
  target nativo do Smallbrain ja existente: PGO_GEN/PGO_USE/PGO_MERGE)
- Processo: make pgo - compila instrumentado, roda bench para coletar
  profile, recompila usando dados reais de execucao.
- Resultado: NPS 1.451.000 -> 1.470.000 (+1.3%)
- Observacao: ganho menor que a faixa teorica tipica (5-15%) citada
  na literatura, provavelmente porque o codigo ja estava bem otimizado
  pelas flags previas (-O3 -flto -march=native) e o bench interno e
  carga de profiling relativamente simples/repetitiva.
- Validacao funcional: go wtime/btime na posicao inicial, comportamento
  identico aos testes anteriores (e2e4, scores consistentes).
- Decisao: manter no pipeline de build. Possivel melhoria futura: usar
  um conjunto de profiling mais diverso (multiplas posicoes de
  abertura/meio-jogo/final) em vez de so o bench padrao, para PGO
  capturar mais variedade de hot paths.

---

## Modulo 2.6 - Tablebases Syzygy 3-4-5 pecas

- Status: Mantido - integrado e validado funcionalmente
- Origem: ja existia suporte no codigo (Fathom), faltava baixar os
  arquivos de dados.
- Fonte: Syzygy-Tablebase-Downloader (mirror Lichess), 290 arquivos
  (145 .rtbw + 145 .rtbz), ~940MB, pasta syzygy_tb/all/
- Validacao funcional: posicao KPK simples, tbhits crescendo
  corretamente durante a busca (1 -> 3 -> 11 -> 16 conforme depth
  aumenta), confirmando consultas reais a tablebase.
- Arquivo auxiliar: start_baduck.sh - configura SyzygyPath
  automaticamente ao iniciar o motor.
- Impacto esperado: precisao absoluta (100%) em finais de ate 5
  pecas, eliminando qualquer erro de avaliacao heuristica nessas
  posicoes. Topo da hierarquia de confianca do Modulo 2.4
  (EGTB > INR > Scale Factor).
- Decisao: manter sempre ativo. Tablebases sao fonte de verdade,
  nao um "experimento" a ser desligado.

---

## Modulo 2.4 - Item 1 (NMP zugzwang-safe) - JA RESOLVIDO NA BASE

- Status: Confirmado - protecao ja existia no Smallbrain original
- Investigacao: search.cpp linha 341, condicao do NMP inclui
  board.nonPawnMat(color) - retorna false se o lado a mover so tem
  rei e peoes, desativando o NMP automaticamente nesses finais
  (exatamente onde zugzwang mutuo e comum).
- Implementacao (board.cpp:299): nonPawnMat = bitboard de
  cavalo|bispo|torre|dama do lado. Padrao correto e equivalente ao
  usado por Stockfish e outros motores fortes.
- Decisao: nenhuma acao necessaria. Item removido da fila de
  prioridade do Modulo 2.4. Proximo item ativo: #2 (formula OCB
  correta do Stockfish, substituindo nosso divisor fixo atual).

---

## Modulo 2.4 - Item 2 (Formula OCB correta) - IMPLEMENTADO

- Status: Mantido - substitui o divisor fixo do Modulo 2.3 original
- Arquivos: eval_scale.h (v2)
- Mudanca: divisor fixo (OCB_MAX_DIVISOR) substituido pela formula
  do Stockfish: sf = 18 + 4 * (numero de peoes passados), escala
  0-64 reescalada para percentual 0-100.
- Nova funcao: countPassedPawns() via bitboard frontSpanMask
  (checa ausencia de peao inimigo na coluna + colunas adjacentes,
  a frente do peao na direcao de promocao).
- Validacao funcional: posicao OCB pura sem peoes (FEN
  8/5k2/8/3b4/8/2K5/3B4/8) converge para score cp 0 a partir da
  depth 5, mesmo comportamento correto do Modulo 2.3 original,
  agora com formula tecnicamente mais precisa (considera numero
  real de peoes passados em vez de divisor fixo).
- NPS: sem regressao (1.423.000 - dentro da variacao normal)
- Decisao: manter. OCB_SCALE_WEIGHT continua em 50 (default),
  pendente de torneio para validacao de Elo.

---

## Modulo 2.3/2.4 - REVERTIDO apos medicao de Elo (bissecao)

- Status: REVERTIDO - OCB_SCALE_WEIGHT e FORTRESS_DETECT_WEIGHT
  voltados para 0 (desligado por padrao)
- Metodo de descoberta: torneio de 1000 jogos (BADUCK v0.7 vs
  Smallbrain baseline, tc=2+0.02) mostrou Elo -11.1 +/- 12.9,
  LOS 4.5% (95.5% confianca de regressao real). Bissecao via
  binario com OCB/Fortress desligados (weight=0), mesmo codigo
  em tudo mais, confirmou: Elo voltou a +2.1 +/- 17.9 (neutro/
  levemente positivo) em 500 jogos.
- Analise por cor (achado adicional): o scaling nao era neutro
  entre cores. Com OCB ligado: brancas 76.3% win rate, pretas
  22.8%. Sem OCB: brancas 71.6%, pretas 35.4%. O modulo estava
  reduzindo desproporcionalmente a vantagem percebida quando
  pretas tinha chance real de jogo, enquanto ajudava brancas a
  defender posicoes ocasionalmente piores. Efeito assimetrico
  nao intencional - a hipotese original (scaling neutro por
  estrutura, independente de cor) nao se confirmou na pratica.
- Aprendizado metodologico: validacao funcional (eval converge
  para 0 em posicao OCB isolada) NAO e suficiente para aprovar
  um modulo. Confirma a necessidade do ciclo completo: implementar
  -> validar funcionalmente -> medir Elo via torneio -> decidir.
  Pulamos a etapa de medicao de Elo antes (Modulo 2.3 original e
  formula corrigida v2), validamos so funcionalmente, e isso
  mascarou uma regressao real por varios commits.
- Codigo: PERMANECE no projeto (eval_scale.h intacto), apenas
  desligado via MODULE_WEIGHT=0. Pode ser re-testado no futuro
  com calibracao diferente (ex: scaling menor, ou so aplicado
  quando o lado com vantagem e quem tem o OCB "bom", nao
  simetrico para os dois lados).
- NPS: 1.413.000 (estavel, sem impacto - confirma que o problema
  era de avaliacao, nao de performance).
- Decisao final: MANTER DESLIGADO ate proxima iteracao de
  calibracao + novo ciclo de medicao.

---

## Metodologia: Effective Branching Factor (EBF) como Diagnostico

Adicionado ao processo de validacao a partir de hoje. Ferramenta:
calc_ebf.sh - calcula EBF = nodes(d)/nodes(d-1) a partir da saida
UCI de uma busca go.

Papel do EBF no processo:
- Ferramenta de DIAGNOSTICO de engenharia, nao metrica de decisao
  final. Ajuda a entender estruturalmente por que um modulo afetou
  profundidade/NPS, isolado de efeito de qualidade tatica.
- Faixa de referencia saudavel: 1.4-1.8 (motores de elite).
- ATENCAO: EBF baixo nao e garantia de qualidade - pode ser sintoma
  de poda excessiva (corte de linhas relevantes). Mesma licao do
  episodio OCB: metrica tecnica isolada pode enganar, so Elo medido
  em torneio confirma se uma mudanca e genuinamente boa.

Baseline atual (BADUCK v0.8, posicao inicial, depth 16):
  EBF medio (depths estaveis): ~1.59-1.66

A partir de agora, todo modulo que mexer em poda/search deve
reportar tanto NPS quanto EBF antes/depois, ALEM do resultado de
Elo via torneio - os tres juntos, nunca um isolado como criterio
de decisao.

---

## Modulo 2.3 v3 - Correcao do bug AND/OR no early-out

- Status: CORRIGIDO - pronto para novo ciclo de medicao de Elo
- Arquivos: eval_scale.h (v3), tune.h (+OCB_MAX_TOTAL_PIECES)
- Causa raiz da regressao de -11 Elo (v0.7): early-out usava AND
  entre "poucos peoes" e "poucas pecas totais". Posicoes com MUITOS
  peoes mas POUCAS pecas totais (final de bispos com 6+ peoes, sem
  outras pecas) escapavam do early-out e recebiam scaling agressivo
  mesmo nao sendo o "final OCB classico" (que tem poucos peoes).
- Correcao: isRelevantEndgamePhase() agora usa duas checagens
  independentes (equivalente a OR) - qualquer uma sozinha ja
  bloqueia o efeito: total_pieces > OCB_MAX_TOTAL_PIECES (10) OU
  total_pawns > OCB_MAX_PAWNS_RELEVANT (5).
- Validacao funcional (3 cenarios):
  1. Final OCB puro sem peoes -> score cp 0 (scaling ativo, correto)
  2. Meio-jogo com torres, 7 peoes -> score cp 107 (sem scaling,
     bloqueado por isPureOcbEndgame, correto)
  3. Final so de bispos com 12 peoes -> score cp 195 (sem scaling,
     bloqueado por OCB_MAX_PAWNS_RELEVANT, correto - este e o
     cenario que vazava no bug v2)
- Proximo passo: torneio de 500-1000 jogos comparando v3 vs
  baseline, mesma metodologia do teste que detectou a regressao
  original, para confirmar que a correcao recupera Elo sem
  reintroduzir o problema.
- Resultado do torneio: (pendente - aguardando torneio atual
  v0.8 terminar para nao competir por recursos de CPU)
- Decisao: (pendente)

---

## Sessao de Revisao de Codigo - 2026-06-23

### Mudancas implementadas

#### LMR History Bonus (implementado - baduck_lmr_v1.exe)
- Substituido `rdepth -= id % 2` (codigo morto com 1 thread) por
  soma de HH + continuation history dividido por 16384.
- Logica: moves com boa historia recebem menos reducao (matematicamente
  superior - correlacao direta com probabilidade de falhar).
- Arquivo: search.cpp
- Status: pendente torneio de validacao vs v0.9

### Fila de melhorias identificadas

#### Busca/Search
1. Investigar pico EBF depth 13 (LMR_BASE ou NMP_BASE_R via SPSA)
2. Corrigir ss->eval com bound check da TT (+2-4 Elo estimado)
3. Corrigir SEE pruning assimetrico (SEE_QUIET_MULT/SEE_CAPT_MULT trocados)
4. Multicut apos Singular Extensions
5. TT flag store mais preciso (verificar best > original_alpha)
6. Expor ASP_DELTA_INIT e ASP_DELTA_MIN_DEPTH para SPSA
7. eval_average ignorar primeiras profundidades no TM
8. TM score drop consecutivo (contador de drops)
9. DTZ move verificar qualidade antes de jogar

#### MovePicker (bugs reais)
10. [BUG] Killers nao verificam validade na movelist (move ilegal possivel)
11. [BUG] scoreMove acessa ss-2 sem verificar ply >= 2 (acesso invalido)
12. Capturas SEE negativas mover para depois dos quiets

#### OCB/Avaliacao
13. Testar OCB_SCALE_WEIGHT_WIN (scaling leve Brancas para recuperar 58%)

#### Modulos
14. Modulo 3.1 - QSearch com xeques
15. Modulo 2.5 - Draw Bias Pretas

### OCB - Estado atual (v0.9)
- OCB_SCALE_WEIGHT: 50 -> 41 (SPSA convergiu)
- OCB_MAX_TOTAL_PIECES: 10 -> 8 (SPSA convergiu)
- OCB_PASSED_BASE/MULT/SF_CAP: expostos, SPSA em andamento
- Logica v6: scaling por sinal do score (score < 0 = Pretas vencendo)
- Resultado torneio v6 vs Smallbrain (771j): +11.3 Elo LOS 94.6%
- Meta: recuperar Brancas para 58% sem regredir Pretas abaixo de 48%

---

## Revisao de Codigo - Adicoes (2026-06-23 sessao 2)

### SEE (see.h) - bugs reais
20. [BUG] Mistura PIECE_VALUES_CLASSICAL e PIECE_VALUES_TUNED no mesmo SEE
21. [BUG] Promocoes nao tratadas no SEE (attacker=PAWN mas vira rainha)
22. [BUG] En passant nao tratado no SEE (to_sq vazio, victim=NONETYPE)

### NNUE (nnue.h)
23. King buckets muito grosseiros (4 quadrantes) - requer retreino de rede
24. Verificar se SCReLU esta implementado em nnue.cpp (header so mostra relu)
25. FEATURE_SIZE como #define - trocar para constexpr

### Evaluation (evaluation.cpp)
26. 50-move scaling usa double desnecessariamente - trocar para inteiro
27. Expor FIFTY_MOVE_SCALE como TUNE_PARAM
28. Investigar impacto no DrawRatio (68%+) - contra-prova empirica
29. Meta estrategica: Pretas nunca perdem - combinar com Draw Bias

### Draw Bias (draw_bias.h)
30. board.sideToMove() != BLACK cria assimetria na arvore
31. Combinar Draw Bias + 50-move scaling suave = "escudo de empate" Pretas

---

## Revisao de Codigo - TT e NNUE (2026-06-24)

### TranspositionTable (tt.h / tt.cpp)
T1. [BUG] allocateMB usa 1e6 em vez de 1024*1024 - TT 5% menor que solicitado
T2. Aging ausente - sem campo gen, entradas antigas nunca descartadas por idade
T3. hashfull amostra sempre primeiras 1000 entradas - enviesado, melhor distribuido

### NNUE (nnue.cpp / nnue.h)
N1. alignas(32) faltando em HIDDEN_WEIGHTS e OUTPUT_BIAS
N2. Ponteiros contiguos em activate/deactivate/move (+NPS)
N3. relu inline explicito: x > 0 ? x : 0
N4. constexpr para FEATURE_SIZE, N_HIDDEN_SIZE, BUCKETS
N5. Unificar activate/deactivate com parametro sign
N6. __restrict nos ponteiros do acumulador
N7. Verificar feof/ferror no init + simplificar carregamento

---

## Revisao de Codigo - board.cpp / timemanager / uci (2026-06-24)

### board.h / board.cpp
B1. Oportunidade: movePiece usar XOR para reduzir operacoes bitboard (6->2)
B2. Oportunidade: updateHash muito longa - refatorar em subfuncoes
B3. [BUG] half_move_clock_ nao incrementado em updateHash - verificar makeMove
B4. [BUG] en passant sem validacao de bounds no setFen
B5. Oportunidade: refreshNNUE usar memcpy em vez de loop
B6. Oportunidade: setFen usar string com reserve em vez de stringstream
B7. [BUG] plies_played_ underflow se fullmove=0 no FEN
B8. [BUG] en passant square sem validacao de range
B9. Oportunidade: isDrawn usar hasLegalMove() em vez de gerar movelist completa
B10. Oportunidade: getFen usar string com reserve
B11. Oportunidade: isRepetition cast size_t->int (UB teorico)
B12. Oportunidade: isDrawn nao verifica KNNK
B13. Oportunidade: unmakeNullMove restaurar hash do state em vez de recalcular
B14. [HOTPATH] us(Color c) faz 6 lookups+5 ORs - manter occ_white_/occ_black_ separados
B15. [BUG POTENCIAL] all() tem assert que recalcula us<>() em release - occupancy pode dessincronizar
B16. Oportunidade: Board copy constructor e operator= duplicados - usar copy-and-swap
B17. Oportunidade: state_history_ como vector heap - usar array estatico MAX_PLY
B18. Oportunidade: kingSQ e kingSq duplicados - remover um

### timemanager.cpp
TM1. mtg=50 hardcoded - candidato a TUNE_PARAM
TM2. overhead=10ms hardcoded - candidato a UCI option
TM3. optimum=total/20 hardcoded - candidato a TUNE_PARAM
TM4. maximum=2*optimum hardcoded - inconsistente com TM_HARDCAP_NUM/DEN
TM5. Oportunidade: alocar mais tempo por fase do jogo (meio-jogo > abertura/final)

### uci.cpp
U1. NormalizeToPawnValue=131 hardcoded - desatualiza se rede mudar
U2. modelWinRate usa coeficientes do Stockfish - WDL impreciso para BADUCK
U3. position() faz refreshNNUE desnecessario - usar makeMove<true> incremental
U4. [BUG] extractSquare sem validacao de bounds - UB com input malformado
U5. [BUG] UCI_MAX_HASH_MB mistura 1024^2 com 1e6 - mesmo bug do allocateMB
