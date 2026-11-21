#!/usr/bin/env bash
# Apaga o cluster "obs" inteiro (dados incluídos). Para só pausar, use: docker stop obs-control-plane
set -euo pipefail
kind delete cluster --name obs
