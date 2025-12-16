#!/bin/bash
set -e

# Get the latest tag, default to v0.0.0 if no tags exist
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")

# Extract version numbers
VERSION=${LATEST_TAG#v}
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

# Increment patch version
PATCH=$((PATCH + 1))
NEW_TAG="v${MAJOR}.${MINOR}.${PATCH}"

echo "Latest tag: $LATEST_TAG"
echo "New tag: $NEW_TAG"
echo ""
read -p "Create and push tag $NEW_TAG? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    git tag -a "$NEW_TAG" -m "Release $NEW_TAG"
    git push origin "$NEW_TAG"
    echo "✓ Tag $NEW_TAG created and pushed. Release workflow triggered."
else
    echo "Aborted."
    exit 1
fi

