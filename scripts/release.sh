#!/usr/bin/env bash
# Tags vX.Y.Z, moves the floating major tag vX, and creates a GitHub release.
# Usage: scripts/release.sh <version>   e.g. scripts/release.sh 1.2.0
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <version>  (e.g. $0 1.2.0)" >&2
  exit 1
fi

version="$1"
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: version must be X.Y.Z (without leading 'v')" >&2
  exit 1
fi

tag="v$version"
major="v${version%%.*}"

if [ -n "$(git status --porcelain)" ]; then
  echo "error: working tree is dirty" >&2
  exit 1
fi

branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$branch" != "main" ]; then
  echo "error: releases must be cut from main (currently on $branch)" >&2
  exit 1
fi

git fetch origin
if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]; then
  echo "error: local main is not in sync with origin/main" >&2
  exit 1
fi

if git rev-parse "$tag" >/dev/null 2>&1; then
  echo "error: tag $tag already exists" >&2
  exit 1
fi

git tag -a "$tag" -m "$tag"
git tag -f -a "$major" -m "$major"
git push origin "$tag"
git push -f origin "$major"

gh release create "$tag" --title "$tag" --generate-notes

echo "Released $tag ($major updated)."
