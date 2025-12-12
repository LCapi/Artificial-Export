#!/usr/bin/env bash
set -euo pipefail

# Project root (defaults to current directory)
ROOT="${1:-.}"

# Normalize to absolute path
ROOT="$(cd "$ROOT" && pwd)"

OUT_TREE="$ROOT/project-tree.txt"
OUT_MD="$ROOT/project-export.md"

# Max file size to export (in bytes)
MAX_FILE_SIZE=$((200 * 1024)) # 200 KB

# Allowed extensions (without the dot)
ALLOWED_EXTS="java kt xml yml yaml properties md txt html js ts json"

# Directories to ignore by name (used in find expressions)
# We do NOT try to build dynamic commands, we just write the expression explicitly.
IGNORE_FIND_EXPR='( -name .git -o -name .idea -o -name .vscode -o -name target -o -name build -o -name out -o -name node_modules -o -name dist )'

echo "== Project exporter =="
echo "Root: $ROOT"
echo "Max file size: $MAX_FILE_SIZE bytes"
echo

# --- Helpers -------------------------------------------------------------

get_ext() {
  # Returns the extension of a file (without dot), or empty string if none
  local filename="$1"
  case "$filename" in
    *.*) echo "${filename##*.}" ;;
    *) echo "" ;;
  esac
}

is_allowed_ext() {
  # Returns 0 (true) if extension is in ALLOWED_EXTS
  local ext="$1"
  for e in $ALLOWED_EXTS; do
    if [ "$e" = "$ext" ]; then
      return 0
    fi
  done
  return 1
}

guess_lang() {
  # Guess code block language for Markdown ``` blocks based on extension
  local ext="$1"
  case "$ext" in
    java) echo "java" ;;
    kt) echo "kotlin" ;;
    xml) echo "xml" ;;
    yml|yaml) echo "yaml" ;;
    properties) echo "" ;;
    md|txt) echo "" ;;
    html) echo "html" ;;
    js) echo "javascript" ;;
    ts) echo "typescript" ;;
    json) echo "json" ;;
    *) echo "" ;;
  esac
}

# --- Generate project-tree.txt ------------------------------------------

echo "Generating $OUT_TREE ..."

{
  echo "[.]"

  # Print all paths (dirs + files), ignoring some directories
  # We use a simple while/read loop instead of arrays and eval.
  find "$ROOT" $IGNORE_FIND_EXPR -prune -o -print | while IFS= read -r path; do
    # Skip root itself
    if [ "$path" = "$ROOT" ]; then
      continue
    fi

    rel="${path#"$ROOT"/}"

    # Skip our own output files
    if [ "$rel" = "project-tree.txt" ] || [ "$rel" = "project-export.md" ]; then
      continue
    fi

    # Depth = number of '/' in relative path
    tmp="${rel//[^\/]/}"
    depth=${#tmp}

    indent=""
    if [ "$depth" -gt 0 ]; then
      for ((i = 0; i < depth; i++)); do
        indent+="  "
      done
    fi

    name="${rel##*/}"

    if [ -d "$path" ]; then
      echo "${indent}[${name}]"
    else
      echo "${indent}- ${name}"
    fi
  done
} > "$OUT_TREE"

echo "OK: $OUT_TREE"
echo

# --- Generate project-export.md ------------------------------------------

echo "Generating $OUT_MD ..."

{
  echo "# Project export"
  echo

  # Only files, still ignoring noisy directories
  find "$ROOT" $IGNORE_FIND_EXPR -prune -o -type f -print | while IFS= read -r file; do
    rel="${file#"$ROOT"/}"

    # Skip our own output files
    if [ "$rel" = "project-tree.txt" ] || [ "$rel" = "project-export.md" ]; then
      continue
    fi

    ext="$(get_ext "$file")"
    if ! is_allowed_ext "$ext"; then
      continue
    fi

    # File size (portable way: wc -c)
    size=$(wc -c < "$file" | tr -d '[:space:]')
    if [ "$size" -gt "$MAX_FILE_SIZE" ]; then
      echo "Skipping $rel (too large: ${size} bytes)" >&2
      continue
    fi

    lang="$(guess_lang "$ext")"

    echo "## FILE: $rel"
    echo "\`\`\`$lang"
    cat "$file"
    echo
    echo "\`\`\`"
    echo
  done
} > "$OUT_MD"

echo "OK: $OUT_MD"
echo
echo "Done. You can now send me 'project-tree.txt' and 'project-export.md'."
