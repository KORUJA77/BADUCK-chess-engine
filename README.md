# BADUCK - UCI Chess Engine

UCI chess engine derived from Smallbrain, focused on performance and asymmetric tuning.

## Philosophy / Motivation

This project is a sandbox for trying out new ideas — the kind that are discussed in forums, shared among friends, or even the "crazy" ones that might not be viable. The goal is to learn, experiment, and contribute back to the computer chess community, regardless of whether the ideas ultimately gain Elo or not. Every test is a lesson.
The name BADUCK is a tribute to my son, who loves chess and used this nickname in his childhood gaming profile.

## Features
- Based on [Smallbrain](https://github.com/Disservin/Smallbrain) (GPLv3)
- NNUE evaluation, Syzygy tablebases
- **Asymmetric singular extensions** – separate parameters for white and black
- Multicut with conditional negative reduction
- Reproducible testing methodology
- Leading/Trailing

## Strength
Latest test (1000 games vs Smallbrain):
- Leading/Trailing (120,-50,3) **( 51,9% | +13,0 Elo)**
- After black tuning: **54.25% (+29.6 Elo)**

## Compilation
```bash
cd src
make clean && make -j4
Credits
All original code belongs to the Smallbrain authors. BADUCK is a derivative work licensed under GPLv3.

Support
My testing hardware is very limited: a 4‑thread processor and a basic graphics card. Running thousands of games for tuning takes days. If you’d like to help me afford cloud computing or a better machine, consider a donation.

Buy Me a Coffee >
https://buymeacoffee.com/alison77

GitHub Sponsors (soon)

Every contribution helps me test crazier ideas and share the results.

License
GNU General Public License v3.0 (see LICENSE)
