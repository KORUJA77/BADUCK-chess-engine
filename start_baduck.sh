#!/bin/bash
# Inicializa o BADUCK com Syzygy ja configurado
SYZYGY_PATH="E:\\ALISON\\CHESS\\BADUCK\\syzygy_tb\\all"
(printf "setoption name SyzygyPath value %s\n" "$SYZYGY_PATH"; cat) | "$(dirname "$0")/src/baduck.exe"
