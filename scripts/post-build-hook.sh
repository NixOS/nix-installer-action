#!/bin/sh
# nix.conf(5) post-build-hook. The daemon runs this as root with almost nothing
# in the environment. This fails fast and leaves the cache alone.
#
# shellcheck disable=SC2154 # cache_dir, work_dir, ignore and max_kb come from $settings
set -euf
IFS=' '

settings="${0%.sh}.env"
[ -r "$settings" ] || exit 0
# shellcheck source=/dev/null
. "$settings"

[ -n "${OUT_PATHS:-}" ] || exit 0

nix=/nix/var/nix/profiles/default/bin/nix

used_kb=$(du -sk "$cache_dir" 2>/dev/null | cut -f1) || used_kb=0
if [ "${used_kb:-0}" -ge "$max_kb" ]; then
  exit 0
fi

work="$work_dir/$$"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work" || exit 0
: >"$work/stamp" || exit 0

# shellcheck disable=SC2086 # OUT_PATHS is a space-separated list and IFS splits it
if ! $nix --extra-experimental-features nix-command \
  copy --to "file://$cache_dir?compression=zstd&parallel-compression=true" $OUT_PATHS; then
  echo "nix-installer-action: could not add $OUT_PATHS to the store cache" >&2
  exit 0
fi

[ -n "$ignore" ] || exit 0

find "$cache_dir" -maxdepth 1 -name '*.narinfo' -newer "$work/stamp" \
  -exec sed -n '/^StorePath:/{s/^.*: *//;p}' {} + >"$work/added" 2>/dev/null || exit 0
[ -s "$work/added" ] || exit 0

for substituter in $ignore; do
  xargs $nix --extra-experimental-features nix-command path-info \
    --store "$substituter" --json-format 1 --json \
    --option connect-timeout 5 --option stalled-download-timeout 20 \
    <"$work/added" >"$work/info" 2>/dev/null || continue

  # jq is missing from the daemon's PATH on macOS runners, and xargs may split
  # the query into several invocations whose concatenated JSON documents jq
  # rejects. Only a top-level key is followed by ':{', so a nested references
  # or deriver value cannot match.
  grep -o '"/nix/store/[^"]*":{' "$work/info" | sed 's/^"//;s/":{$//' >"$work/prune" || continue

  while read -r storepath; do
    hash="${storepath#/nix/store/}"
    narinfo="$cache_dir/${hash%%-*}.narinfo"
    [ -f "$narinfo" ] || continue
    nar="$(sed -n '/^URL:/{s/^.*: *//;p}' "$narinfo")"
    rm -f "$narinfo" "$cache_dir/$nar"
  done <"$work/prune"
done

exit 0
