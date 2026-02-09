#!/usr/bin/env bash
set -euo pipefail

# Removes downloaded models and build artifacts so the next launch
# re-downloads and re-loads everything from scratch.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ASR models (FluidAudio)
ASR_DIR="$HOME/Library/Application Support/FluidAudio/Models"
if [ -d "$ASR_DIR" ]; then
  echo "Removing ASR models: $ASR_DIR"
  rm -rf "$ASR_DIR"
fi

# LLM cleanup models (HuggingFace Hub)
HF_DIR="$HOME/Documents/huggingface"
if [ -d "$HF_DIR" ]; then
  echo "Removing HuggingFace models: $HF_DIR"
  rm -rf "$HF_DIR"
fi

# Build artifacts
if [ -d "$ROOT_DIR/build" ]; then
  echo "Removing build output: $ROOT_DIR/build"
  rm -rf "$ROOT_DIR/build"
fi

echo "Clean complete. Next launch will re-download all models."
