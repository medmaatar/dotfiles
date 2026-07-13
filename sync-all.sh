#!/bin/bash

# --- CONFIGURATION ---
# Replace these placeholders with your actual tokens and usernames
GH_USER="medmaatar"

GL_USER="maatarmed" # Change if your GitLab username is different
BASE_DIR=~/Work/github.com/maatarmed
# Load environment variables from the .env file
# (Adjust the path if your .env file is saved somewhere else)
if [ -f ".env" ]; then
  source ".env"
else
  echo "❌ Error: .env file not found! Please create it with your tokens."
  exit 1
fi
# Logging setup
LOG_FILE="$BASE_DIR/sync_errors.log"

# Set visibility default for new repos: "true"/"false" for GitHub, "private"/"public" for GitLab
PRIVATE_REPOS=true
GL_VISIBILITY="private"

# --- START SCRIPT ---
mkdir -p "$BASE_DIR"
cd "$BASE_DIR" || exit

echo "🚀 Starting Dual-Platform Sync (GitHub & GitLab)..."
echo "Scanning folders in: $BASE_DIR"
echo "--- Sync Run: $(date) ---" >>"$LOG_FILE"

CREATED_GH=0
CREATED_GL=0
PROCESSED=0

for folder in */; do
  [ -e "$folder" ] || continue

  repo_name="${folder%/}"

  # --- NEW: Ignore the playground folder ---
  if [ "$repo_name" = "playground" ]; then
    echo "  → ⏭️ Skipping '$repo_name' directory..."
    continue
  fi
  # -----------------------------------------

  echo "--------------------------------------------------"
  echo "📁 Processing: $repo_name"

  cd "$repo_name" || continue

  # 1. Initialize local Git repo if it doesn't exist
  if [ ! -d ".git" ]; then
    echo "  → Local Git environment missing. Initializing..."
    git init -q
    git checkout -q -b main
    git add .
    git commit -q -m "Initial commit" >>"$LOG_FILE" 2>&1
  else
    git branch -M main >>"$LOG_FILE" 2>&1
  fi

  # 2. Check on GitHub
  GH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/repos/$GH_USER/$repo_name")

  if [ "$GH_STATUS" -eq 404 ]; then
    echo "  → 🐙 Missing on GitHub. Creating..."
    curl -s -H "Authorization: token $GH_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      -d "{\"name\":\"$repo_name\", \"private\": $PRIVATE_REPOS}" \
      "https://api.github.com/user/repos" >/dev/null
    ((CREATED_GH++))
  fi

  # 3. Check on GitLab
  ENCODED_PATH="${GL_USER}%2F${repo_name}"
  GL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "PRIVATE-TOKEN: $GL_TOKEN" \
    "https://gitlab.com/api/v4/projects/$ENCODED_PATH")

  if [ "$GL_STATUS" -eq 404 ]; then
    echo "  → 🦊 Missing on GitLab. Creating..."
    curl -s -H "PRIVATE-TOKEN: $GL_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"name\":\"$repo_name\", \"path\":\"$repo_name\", \"visibility\": \"$GL_VISIBILITY\"}" \
      "https://gitlab.com/api/v4/projects" >/dev/null
    ((CREATED_GL++))
  fi

  # 4. Configure Remotes
  GH_URL="git@github.com:$GH_USER/$repo_name.git"
  GL_URL="git@gitlab.com:$GL_USER/$repo_name.git"

  if git remote | grep -q "^github$"; then
    git remote set-url github "$GH_URL"
  else
    git remote add github "$GH_URL"
  fi

  if git remote | grep -q "^gitlab$"; then
    git remote set-url gitlab "$GL_URL"
  else
    git remote add gitlab "$GL_URL"
  fi

  # 5. Execute Push or Pull for GitHub
  echo "--- $repo_name (GitHub) ---" >>"$LOG_FILE"
  if [ "$GH_STATUS" -eq 404 ]; then
    echo "  → Pushing to GitHub..."
    git push -u github main >>"$LOG_FILE" 2>&1 || echo "    ⚠️ GitHub push failed. Check sync_errors.log"
  else
    echo "  → Repo exists on GitHub. Pulling..."
    git pull github main >>"$LOG_FILE" 2>&1 || echo "    ⚠️ GitHub pull failed (possible conflict). Check sync_errors.log"
  fi

  # 6. Execute Push or Pull for GitLab
  echo "--- $repo_name (GitLab) ---" >>"$LOG_FILE"
  if [ "$GL_STATUS" -eq 404 ]; then
    echo "  → Pushing to GitLab..."
    git push -u gitlab main >>"$LOG_FILE" 2>&1 || echo "    ⚠️ GitLab push failed. Check sync_errors.log"
  else
    echo "  → Repo exists on GitLab. Pulling..."
    git pull gitlab main >>"$LOG_FILE" 2>&1 || echo "    ⚠️ GitLab pull failed (possible conflict). Check sync_errors.log"
  fi

  ((PROCESSED++))
  cd "$BASE_DIR" || exit
done

echo "--------------------------------------------------"
echo "✓ Sync Complete! Any errors are logged in $LOG_FILE"
echo "Total processed: $PROCESSED | New GitHub Repos: $CREATED_GH | New GitLab Repos: $CREATED_GL"
