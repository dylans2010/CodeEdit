#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Starting {{PROJECT_NAME}} ===${NC}"

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

info "System: $(uname -s) on $(uname -m)"
info "Completed {{PROJECT_NAME}} execution successfully."
