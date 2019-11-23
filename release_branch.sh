#!/usr/bin/env bash

# Copyright Reinhard Nägele. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset

show_help() {
cat << EOF
Usage: $(basename "$0") <options>

    -h, --help                Display help
    -a, --paths-to-add        A list of comma-separated paths to add to Git for the tag
    -e, --paths-to-exclude    A list of comma-separated paths to exclude from Git for the tag
    -s, --skip-push           Skip pushing the tag
    -b, --build-cmd           The build command to run
EOF
}

main() {
    local paths_to_add=
    local paths_to_exclude=
    local skip_push=
    local build_cmd=

    while :; do
        case "${1:-}" in
            -h|--help)
                show_help
                exit
                ;;
            -a|--paths-to-add)
                if [[ -n "${2:-}" ]]; then
                    paths_to_add="$2"
                    shift
                else
                    echo "ERROR: '--paths-to-add' cannot be empty." >&2
                    show_help
                    exit 1
                fi
                ;;
            -e|--paths-to-exclude)
                if [[ -n "${2:-}" ]]; then
                    paths_to_exclude="$2"
                    shift
                else
                    echo "ERROR: '--paths-to-exclude' cannot be empty." >&2
                    show_help
                    exit 1
                fi
                ;;
            -b|--build-cmd)
                if [[ -n "${2:-}" ]]; then
                    build_cmd="$2"
                    shift
                else
                    echo "ERROR: '--build-cmd' cannot be empty." >&2
                    show_help
                    exit 1
                fi
                ;;
            -s|--skip-push)
                skip_push=true
                ;;
            *)
                break
                ;;
        esac

        shift
    done

    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    local current_ref
    current_ref=$(git rev-parse --short HEAD)

    local release_branch="release/$current_branch"

    git checkout -b "$release_branch" 2> /dev/null || git checkout "$release_branch"
    trap 'git switch -' EXIT

    git read-tree -u --reset "$current_branch"

    local git_dir
    git_dir=$(git rev-parse --git-dir)
    git rev-parse "$current_branch" > "$git_dir/MERGE_HEAD"

    git commit -m "Merge branch '$current_branch' into '$release_branch'"

    bash -c "$build_cmd"

    export IFS=','
    for path in $paths_to_exclude; do
        echo "Removing path from Git: $path"
        git rm -r -- "$path"
    done
    for path in $paths_to_add; do
        echo "Adding path to Git: $path"
        git add --force -- "$path"
    done

    git status

    echo 'Committing changes...'
    git commit --message "Update release branch for ref: $current_ref"

    if [[ -z "$skip_push" ]]; then
        echo "Pushing branch '$release_branch'..."

        if [[ -n "${GITHUB_TOKEN:-}" ]] && [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
            repo_url="https://x-access-token:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY.git"
            git push "$repo_url" "$release_branch"
        else
            git push origin "$release_branch"
        fi
    fi
}

main "$@"
