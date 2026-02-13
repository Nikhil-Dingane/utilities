#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="."
cd "$REPO_ROOT"

# 1) Checkout the changes from the specified files
#git checkout -- 

# 2) Take the diff in the current directory and redirect to a patch file
PATCH_FILE="./remote.patch"
MODE="unstaged"
DIFF_PATHS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s) MODE="staged"; shift ;;
    -u) MODE="unstaged"; shift ;;
    -all) MODE="all"; shift ;;
    -n)
      if [[ $# -lt 2 ]]; then
        echo "Error: -n requires a filename" >&2
        exit 1
      fi
      PATCH_FILE="$2"
      shift 2
      ;;
    -f)
      shift
      while [[ $# -gt 0 && "$1" != -* ]]; do
        DIFF_PATHS+=("$1")
        shift
      done
      if [[ ${#DIFF_PATHS[@]} -eq 0 ]]; then
        echo "Error: -f requires at least one file path" >&2
        exit 1
      fi
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

case "$MODE" in
  staged)
    if [[ ${#DIFF_PATHS[@]} -gt 0 ]]; then
      git diff --cached --no-color -- "${DIFF_PATHS[@]}" > "$PATCH_FILE"
    else
      git diff --cached --no-color > "$PATCH_FILE"
    fi
    ;;
  unstaged)
    if [[ ${#DIFF_PATHS[@]} -gt 0 ]]; then
      git diff --no-color -- "${DIFF_PATHS[@]}" > "$PATCH_FILE"
    else
      git diff --no-color > "$PATCH_FILE"
    fi
    ;;
  all)
    if [[ ${#DIFF_PATHS[@]} -gt 0 ]]; then
      git diff --cached --no-color -- "${DIFF_PATHS[@]}" > "$PATCH_FILE"
      git diff --no-color -- "${DIFF_PATHS[@]}" >> "$PATCH_FILE"
    else
      git diff --cached --no-color > "$PATCH_FILE"
      git diff --no-color >> "$PATCH_FILE"
    fi
    ;;
esac

# 3) Apply the patch on the remote work directory (passwordless)
REMOTE="nikhil@127.0.0.1"
REMOTE_DIR="~/work"
SSHPASS="password"

sshpass -p "$SSHPASS" scp "$PATCH_FILE" "$REMOTE:$REMOTE_DIR/"
sshpass -p "$SSHPASS" ssh "$REMOTE" "cd $REMOTE_DIR && git apply $PATCH_FILE"
