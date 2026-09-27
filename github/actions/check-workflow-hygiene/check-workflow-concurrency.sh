#!/usr/bin/env bash
# Verify every GitHub Actions workflow under .github/workflows/ declares a
# deliberate concurrency policy — either a top-level `concurrency:` key, or an
# explicit opt-out comment recording why one was skipped on purpose.
# actionlint has no built-in rule for a missing key, so this is enforced here
# instead. Ported from dfadler/dfadler.com's check-workflow-concurrency.sh.
#
# A workflow can also record its opt-out at the JOB level rather than the
# workflow level (e.g. a workflow where each job already carries its own
# tailored concurrency group and a single top-level group would be wrong) —
# what matters is that the choice is deliberate and explained, not where in
# the file it's spelled out.
set -uo pipefail

EXIT_OK=0
EXIT_FAILURE=1
EXIT_USAGE=2

usage() {
  cat <<'EOF'
Usage: check-workflow-concurrency.sh [-h|--help] [path ...]

Fails if a workflow file under the given path(s) (default:
.github/workflows) has neither a top-level `concurrency:` key nor an
explicit opt-out comment of the form:

  # concurrency: none — <reason>

Accepts individual .yml/.yaml files and/or directories (searched
recursively) as arguments.
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
    echo "check-workflow-concurrency.sh: no such file or directory: $t" >&2
    exit "$EXIT_USAGE"
  fi
done

# Opt-out marker: a comment recording a deliberate, explained skip. Requires
# actual reason text after "none" (a dash/em-dash followed by non-space) so a
# bare `# concurrency: none` with no rationale doesn't pass.
opt_out_pattern='^[[:space:]]*#[[:space:]]*concurrency:[[:space:]]*none[[:space:]]*(—|-)[[:space:]]+[^[:space:]]'

missing=()

while IFS= read -r -d '' file; do
  if grep -qE '^concurrency:' "$file"; then
    continue
  fi
  if grep -qE "$opt_out_pattern" "$file"; then
    continue
  fi
  missing+=("$file")
done < <(find "${targets[@]}" -type d -name node_modules -prune -o -type f \( -name '*.yml' -o -name '*.yaml' \) -print0)

if [ "${#missing[@]}" -gt 0 ]; then
  echo "::error::Workflow file(s) missing a top-level 'concurrency:' key and no opt-out comment:" >&2
  printf '  %s\n' "${missing[@]}" >&2
  echo "Add a top-level concurrency block, or record a deliberate opt-out as:" >&2
  echo '  # concurrency: none — <reason>' >&2
  exit "$EXIT_FAILURE"
fi

echo "✓ Every workflow file declares a deliberate concurrency policy."
