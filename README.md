# BADUCK - UCI Chess Engine

UCI chess engine derived from Smallbrain, focused on performance and asymmetric tuning.

## Features
- Based on [Smallbrain](https://github.com/Disservin/Smallbrain) (GPLv3)
- NNUE evaluation, Syzygy tablebases
- **Asymmetric singular extensions** – separate parameters for white and black
- Multicut with conditional negative reduction
- Reproducible testing methodology

## Strength
Estimated Elo: ~2300–2500 (evolving)

Latest test (200 games vs Smallbrain):
- After black tuning: **54.25% (+29.6 Elo)**

## Compilation
```bash
cd src
make clean && make -j4
Credits
All original code belongs to the Smallbrain authors. BADUCK is a derivative work licensed under GPLv3.

Support
If you'd like to help me run longer tests (my hardware is limited), consider a donation:

Buy Me a Coffee

GitHub Sponsors (soon)

License
GNU General Public License v3.0 (see LICENSE)
