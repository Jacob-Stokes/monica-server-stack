#!/usr/bin/env bash
# The installer: the same as ./monica-stack install.
exec "$(dirname "$0")/monica-stack" install "$@"
