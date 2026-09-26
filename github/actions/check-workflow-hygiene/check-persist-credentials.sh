#!/usr/bin/env bash
# Verify every `actions/checkout` step under .github/workflows/*.yml
# explicitly declares `persist-credentials`. actions/checkout defaults to
# `persist-credentials: true`, writing the GITHUB_TOKEN into the workspace's
# git config where anything that runs afterwards — including PR-controlled
# package scripts and tests — can read it (the "artipacked" pattern). Nothing
# enforces that by default, so a new workflow or a new checkout step silently
# reintroduces the risk unless this runs on every PR. Ported from
# dfadler/dfadler.com's check-persist-credentials.sh.
#
# Rules, per checkout step (a step's `uses: actions/checkout@` key is
# recognized whether or not it shares the dash's own line — `- name: X` /
# `  uses: ...` is a valid style):
#   - `persist-credentials` omitted entirely           -> flagged.
#   - `persist-credentials: false`                     -> clean.
#   - `persist-credentials: true` with a
#     `# zizmor: ignore[artipacked]` annotation on the
#     same or an adjacent line                         -> clean (justified).
#   - `persist-credentials: true` with no annotation   -> flagged.
#
# This is a small, targeted grep/state-machine check rather than pulling in
# zizmor for one rule.
set -uo pipefail

EXIT_OK=0
EXIT_FAILURE=1
EXIT_USAGE=2

usage() {
  cat <<'EOF'
Usage: check-persist-credentials.sh [-h|--help] [path ...]

Fails if any `actions/checkout` step under the given path(s) (default:
.github/workflows) omits an explicit `persist-credentials` key, or sets
`persist-credentials: true` without an adjacent
`# zizmor: ignore[artipacked]` annotation.

Accepts individual .yml/.yaml files and/or directories (searched
recursively) as arguments, mirroring check-workflow-concurrency.sh.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h | --help)
      usage
      exit "$EXIT_OK"
      ;;
  esac
done

targets=("$@")
[ "${#targets[@]}" -eq 0 ] && targets=(.github/workflows)

for t in "${targets[@]}"; do
  if [ ! -e "$t" ]; then
    echo "check-persist-credentials.sh: no such file or directory: $t" >&2
    exit "$EXIT_USAGE"
  fi
done

annotation_pattern='zizmor:[[:space:]]*ignore\[artipacked\]'

problems=()

# Scans one workflow file for actions/checkout steps missing (or
# insufficiently justified) persist-credentials. Reads the whole file into an
# array so the persist-credentials line's neighbors can be inspected directly
# (the "adjacent line" annotation rule) without a second pass.
check_file() {
  local file="$1"
  # Avoid mapfile: bash 3.2 (macOS's default /bin/bash) doesn't have it.
  local lines=()
  local raw_line
  while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    lines+=("$raw_line")
  done <"$file"
  local n=${#lines[@]}

  # A "block" is one top-level list item (a `- ...` step) plus everything
  # indented under it. A step's `uses:` key doesn't have to share the dash's
  # own line — `- name: Checkout` / `  uses: actions/checkout@v7` is a valid
  # style — so a block is only classified as a checkout step once ANY line
  # inside it matches `uses: actions/checkout@`, not just its opening line.
  local in_block=0
  local -i block_indent=0
  local block_is_checkout=0
  local checkout_line=0
  local found_pc=0
  local pc_value=""
  local pc_line=0

  local i line stripped indent is_comment is_list_item

  # Closes the currently-open block (if any). Only a block that turned out to
  # be a checkout step is judged; a non-checkout block (or a bare boundary
  # with nothing open) is discarded silently.
  close_block() {
    if [ "$in_block" -eq 1 ] && [ "$block_is_checkout" -eq 1 ]; then
      if [ "$found_pc" -eq 0 ]; then
        problems+=("$file:$checkout_line: actions/checkout step has no explicit 'persist-credentials' key")
      elif [ "$pc_value" = "true" ]; then
        local lo=$((pc_line - 2))
        local hi=$pc_line
        [ "$lo" -lt 0 ] && lo=0
        [ "$hi" -ge "$n" ] && hi=$((n - 1))
        local annotated=0
        local j
        for ((j = lo; j <= hi; j++)); do
          if [[ "${lines[$j]}" =~ $annotation_pattern ]]; then
            annotated=1
            break
          fi
        done
        if [ "$annotated" -eq 0 ]; then
          problems+=("$file:$pc_line: persist-credentials: true with no '# zizmor: ignore[artipacked]' annotation")
        fi
      fi
    fi
    in_block=0
    block_is_checkout=0
    found_pc=0
    pc_value=""
  }

  for ((i = 0; i < n; i++)); do
    line="${lines[$i]}"

    # Blank/whitespace-only lines never end or start a block.
    if [[ "$line" =~ ^[[:space:]]*$ ]]; then
      continue
    fi

    if [[ "$line" =~ ^([[:space:]]*)(.*)$ ]]; then
      indent=${#BASH_REMATCH[1]}
      stripped="${BASH_REMATCH[2]}"
    else
      continue
    fi

    is_comment=0
    [[ "$stripped" == \#* ]] && is_comment=1
    is_list_item=0
    [[ "$stripped" == "-"* ]] && is_list_item=1

    # A sibling list item (or a dedent out of the steps list entirely) ends
    # the currently-open block. Comments never count as a boundary — they're
    # frequently indented at the step's own level while still documenting
    # its `with:` block.
    if [ "$in_block" -eq 1 ] && [ "$is_comment" -eq 0 ] && [ "$indent" -le "$block_indent" ]; then
      close_block
    fi

    # Only a list item can OPEN a new top-level block. A list item nested
    # deeper than the current block (e.g. a YAML list value inside `with:`)
    # is left alone as plain body content, not treated as a sibling step.
    if [ "$is_list_item" -eq 1 ] && [ "$in_block" -eq 0 ]; then
      in_block=1
      block_indent=$indent
      block_is_checkout=0
      found_pc=0
      pc_value=""
    fi

    if [ "$in_block" -eq 1 ] && [ "$is_comment" -eq 0 ]; then
      if [[ "$stripped" =~ uses:[[:space:]]*actions/checkout@ ]]; then
        block_is_checkout=1
        checkout_line=$((i + 1))
      fi
      if [[ "$stripped" =~ ^persist-credentials:[[:space:]]*[\"\']?(true|false) ]]; then
        found_pc=1
        pc_value="${BASH_REMATCH[1]}"
        pc_line=$((i + 1))
      fi
    fi
  done

  close_block
}

while IFS= read -r -d '' file; do
  check_file "$file"
done < <(find "${targets[@]}" -type d -name node_modules -prune -o -type f \( -name '*.yml' -o -name '*.yaml' \) -print0)

if [ "${#problems[@]}" -gt 0 ]; then
  echo "::error::actions/checkout step(s) with an unjustified persist-credentials setting:" >&2
  printf '  %s\n' "${problems[@]}" >&2
  echo "Declare 'persist-credentials: false', or 'persist-credentials: true' with a" >&2
  echo "'# zizmor: ignore[artipacked]' annotation and a justification comment." >&2
  exit "$EXIT_FAILURE"
fi

echo "✓ Every actions/checkout step declares an explicit, justified persist-credentials."
