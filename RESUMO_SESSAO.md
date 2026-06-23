# BADUCK - Estado do Projeto (Resumo para nova sessão)
## Localização
E:/ALISON/CHESS/BADUCK/
## Build normal
cd /e/ALISON/CHESS/BADUCK/src && make -j4
## Executável de produção atual
baduck_v0.8.exe (na raiz do BADUCK)
Elo: neutro vs Smallbrain baseline (-3.1 ±12.6, LOS 31%)
NPS: ~1.413-1.470k (+12% vs baseline)
EBF: ~1.59-1.66
## Módulos ativos
- 1.1 SPSA tune.h
- 1.2 Time Management parametrizado
- 1.3 PGO
- 2.6 Tablebases Syzygy (syzygy_tb/all/, 290 arquivos)
## Módulos desligados (weight=0, código existe)
- 2.3 OCB scaling — ABANDONADO definitivamente (-24 Elo na melhor tentativa v4)
- 2.5 Draw Bias pretas — pendente validação de padrão de cor
## Próximos passos em ordem
1. SPSA dos parâmetros TM_* (Time Management):
   ./spsa_tune.sh ./baduck_tuning.exe TM_NODE_FRACTION_BASE 110 95 130 5 20 20
2. Livro de aberturas balanceado (20 posições, geração via motor pendente)
3. Módulo 2.5 (Draw Bias): rodar 300-500j com weight=0 para confirmar padrão de cor
4. Módulo 3.1 (QSearch com xeques)
## Regra crítica aprendida
NUNCA fazer git checkout em arquivo antes de comitar mudanças nele.
Sequência correta: adicionar parâmetro → comitar → mudar weight para teste → git checkout.
## Compilação com -DTUNING (sem quebrar EVALFILE)
sed -i '10s/$/ -DTUNING/' src/Makefile
make -C src clean && make -C src -j4
cp src/baduck.exe baduck_tuning.exe
git checkout src/Makefile
## Torneio padrão de medição (1000j, tc=2+0.02)
cutechess-cli \
    -engine cmd=./NOVO.exe name=NOVO \
    -engine cmd=./baduck_v0.8.exe name=BADUCK_v0.8 \
    -each proto=uci tc=2+0.02 option.Hash=16 option.Threads=1 \
    -games 1000 -concurrency 2 -repeat -recover \
    -openings file=openings.epd format=epd order=random \
    -pgnout result_NOVO_vs_v08.pgn -ratinginterval 50
