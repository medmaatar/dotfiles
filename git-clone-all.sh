#!/bin/bash

# GitHub token (required for private repos and collaboration access)
TOKEN="https://github.com/settings/tokens"
USERNAME="medmaatar"

# Create directory for repos
mkdir -p ~/github
cd ~/github

echo "Fetching all repos (owned, collaborated, and member)..."

PAGE=1
CLONED=0
SKIPPED=0

while true; do
  # type=all includes: owner, collaborator, and organization member repos
  REPOS=$(curl -s -H "Authorization: token $TOKEN" \
    "https://api.github.com/user/repos?per_page=100&type=all&page=$PAGE" | \
    jq -r '.[].ssh_url')

  # Break if no more repos
  [ -z "$REPOS" ] && break

  while IFS= read -r repo_url; do
    # Extract repo name from URL
    repo_name=$(basename "$repo_url" .git)

    if [ -d "$repo_name" ]; then
      echo "⟳  Pulling updates: $repo_name"
      git -C "$repo_name" pull --quiet
      ((SKIPPED++))
    else
      echo "↓  Cloning: $repo_url"
      git clone --quiet "$repo_url"
      ((CLONED++))
    fi
  done <<< "$REPOS"

  ((PAGE++))
done

echo ""
echo "✓ Done! Cloned: $CLONED | Updated: $SKIPPED"
echo "Repos saved to: ~/github"