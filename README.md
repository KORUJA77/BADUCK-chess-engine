# BADUCK - UCI Chess Engine

UCI chess engine derived from Smallbrain, focused on performance and asymmetric tuning.

<img width="1024" height="559" alt="image" src="https://github.com/user-attachments/assets/913ae213-4212-4c59-8e41-b25fe7527ea9" />

## Philosophy / Motivation

This project is a sandbox for trying out new ideas — the kind that are discussed in forums, shared among friends, or even the "crazy" ones that might not be viable. The goal is to learn, experiment, and contribute back to the computer chess community, regardless of whether the ideas ultimately gain Elo or not. Every test is a lesson.
The name **BADUCK** is a tribute to my son, who loves chess and used this nickname in his childhood gaming profile.

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

## The Asymmetry Journey: From Color to State

When **BADUCK** started, the dream was a fully asymmetric engine: white pieces
always attacking, black pieces always defending – each side with its own
tuned parameters for search and evaluation. 

Early tests proved that splitting parameters by color (`_WHITE` / `_BLACK`)
could indeed bring gains, especially for the black side (which often
plays under pressure). However, tuning these parameters was extremely
difficult: the signal was weak, noise dominated, and my limited hardware
(4-thread CPU, basic GPU) made large‑scale testing a true marathon.
Many promising candidates turned out to be statistical ghosts.

The breakthrough came when we realized that the real asymmetry is not
about which color you play, but about **who is ahead on the board**.
A position where the engine is leading calls for a different style than
one where it is trailing – regardless of the color of the pieces.
This insight led to the **Leading/Trailing state machine**.

### How it works
- Every search iteration, the root score is evaluated.
- Hysteresis and a confirmation counter prevent state flickering.
- Three game states: **Leading** (score > +120 cp), **Trailing** (score < -50 cp), and **Neutral**.
- The state selects which parameter set to use for singular extensions,
  multicut reduction, and now also LMR base and razor margin.

### Results so far
- The Leading/Trailing system alone brought **+13 Elo** against the
  Smallbrain baseline (1000 games).
- Expanding the state machine to LMR and razor margins showed a further
  small improvement (51.5% vs the original LT version in direct match).
- We are currently tuning the leading and trailing values for LMR and
  razor margins, while keeping the neutral values at their original,
  well‑tested defaults.

### A note on patience
All development and testing is done on a **4‑thread processor with no
dedicated GPU**. A single grid of 10,000 games can take a full day.
Progress is slow, but every commit is validated with direct matches
(1,000+ games) before it lands. If you enjoy the project and want to
help me afford cloud computing or a better machine, consider a donation
**(Buy Me a Coffee)**. Your support means faster
iteration and bolder experiments.

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
