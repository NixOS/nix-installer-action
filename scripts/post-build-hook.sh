#!/bin/sh
# nix.conf(5) post-build-hook. The daemon runs this as root with almost nothing
# in the environment. This fails fast and leaves the cache alone.
#
# shellcheck disable=SC2154 # cache_dir and max_kb come from $settings
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

# shellcheck disable=SC2086 # OUT_PATHS is a space-separated list and IFS splits it
if ! $nix --extra-experimental-features nix-command \
  copy --to "file://$cache_dir?compression=zstd&parallel-compression=true" $OUT_PATHS; then
  echo "nix-installer-action: could not add $OUT_PATHS to the store cache" >&2
fi

exit 0
