#!/usr/bin/env bash

set -o errexit
set -o nounset
set -x

SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")

GITHUB_TOKEN=${INPUT_TOKEN:-}
export GITHUB_TOKEN

args=(--build-cmd "${INPUT_BUILD_CMD?'build_cmd' input is required}")

if [[ -n "${INPUT_PATHS_TO_ADD:-}" ]]; then
    args+=(--paths-to-add "${INPUT_PATHS_TO_ADD}")
fi

if [[ -n "${INPUT_PATHS_TO_REMOVE:-}" ]]; then
    args+=(--paths-to-remove "${INPUT_PATHS_TO_REMOVE}")
fi

# Make sure we are on a branch. GitHub does a detached checkout.
branch="${GITHUB_REF##*/}"
git checkout -B "$branch"

"$SCRIPT_DIR/release_branch.sh" "${args[@]}"
