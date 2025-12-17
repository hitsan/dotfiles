#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/prompt/instructions.md"
DEST_DIR="${PWD}/.claude"

mkdir -p "${DEST_DIR}"
cp "${SOURCE_FILE}" "${DEST_DIR}/instructions.md"

echo "✓ Synced to ${DEST_DIR}/instructions.md"
