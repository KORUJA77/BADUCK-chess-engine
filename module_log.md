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
