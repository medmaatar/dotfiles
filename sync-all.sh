#!/bin/bash

# --- CONFIGURATION ---
GH_USER="medmaatar"
GL_USER="maatarmed"
BASE_DIR=~/Work/github.com/maatarmed

# Load environment variables from the .env file
if [ -f "$BASE_DIR/.env" ]; then
  source "$BASE_DIR/.env"
elif [ -f ".env" ]; then
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
COLLAB_PULLED=0

for folder in */; do
  [ -e "$folder" ] || continue

  repo_name="${folder%/}"

  # --- Ignore specific folders ---
  if [ "$repo_name" = "playground" ]; then
    echo "  → ⏭️ Skipping '$repo_name' directory..."
    continue
  fi

  echo "--------------------------------------------------"
  echo "📁 Processing: $repo_name"
  cd "$repo_name" || continue

  # --- OWNERSHIP GUARD: If collaborator, ONLY pull ---
  IS_COLLAB=false
  if [ -d ".git" ]; then
    ORIGIN_URL=$(git config --get remote.origin.url 2>/dev/null)
    if [ -n "$ORIGIN_URL" ]; then
      if ! echo "$ORIGIN_URL" | grep -qiE "[:/]($GH_USER|$GL_USER)/"; then
        IS_COLLAB=true
      fi
    fi
  fi

  if [ "$IS_COLLAB" = true ]; then
    echo "  → 🤝 Collaborator repo detected. Pulling updates only..."
    echo "--- $repo_name (Collaborator Pull) ---" >>"$LOG_FILE"

    # Auto-commit any unstaged changes to prevent pull conflicts
    if [ -n "$(git status --porcelain)" ]; then
      git add .
      git commit -q -m "Auto-commit before collab pull: $(date +'%Y-%m-%d %H:%M')" >>"$LOG_FILE" 2>&1
    fi

    # Pull from the default upstream (usually 'origin')
    git pull --rebase >>"$LOG_FILE" 2>&1 || echo "    ⚠️ Pull failed. Check sync_errors.log"

    ((COLLAB_PULLED++))
    cd "$BASE_DIR" || exit
    continue
  fi

  # --- GIT INITIALIZATION & AUTO-COMMIT (For Personal Repos) ---
  if [ ! -d ".git" ]; then
    echo "  → Local Git environment missing. Initializing..."
    git init -q
  fi

  # Check if there are unstaged changes and auto-commit them
  if [ -n "$(git status --porcelain)" ]; then
    echo "  → Auto-committing uncompleted local changes..."
    git add .
    git commit -q -m "Auto-commit before sync: $(date +'%Y-%m-%d %H:%M')" >>"$LOG_FILE" 2>&1
  fi

  # Check if the repository is completely empty (no commits yet)
  if ! git rev-parse HEAD >/dev/null 2>&1; then
    echo "  → Repository is empty. Creating initial commit..."
    touch .gitkeep
    git add .gitkeep
    git commit -q -m "Initial automated commit" >>"$LOG_FILE" 2>&1
  fi

  # Ensure the branch is strictly named 'main'
  git branch -M main >>"$LOG_FILE" 2>&1

  # --- CHECK & CREATE ON GITHUB ---
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

  # --- CHECK & CREATE ON GITLAB ---
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

  # --- CONFIGURE REMOTES ---
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

  # --- EXECUTE PUSH/PULL ---
  echo "--- $repo_name (GitHub) ---" >>"$LOG_FILE"
  if [ "$GH_STATUS" -eq 404 ]; then
    echo "  → Pushing to GitHub..."
    git push github main >>"$LOG_FILE" 2>&1 || echo "    ⚠️ GitHub push failed."
  else
    echo "  → Repo exists on GitHub. Syncing..."
    git pull --rebase github main >>"$LOG_FILE" 2>&1
    git push github main >>"$LOG_FILE" 2>&1
  fi

  echo "--- $repo_name (GitLab) ---" >>"$LOG_FILE"
  if [ "$GL_STATUS" -eq 404 ]; then
    echo "  → Pushing to GitLab..."
    git push gitlab main >>"$LOG_FILE" 2>&1 || echo "    ⚠️ GitLab push failed."
  else
    echo "  → Repo exists on GitLab. Syncing..."
    git pull --rebase gitlab main >>"$LOG_FILE" 2>&1
    git push gitlab main >>"$LOG_FILE" 2>&1
  fi

  ((PROCESSED++))
  cd "$BASE_DIR" || exit
done

echo "--------------------------------------------------"
echo "✓ Sync Complete! Any errors are logged in $LOG_FILE"
echo "Total Personal Repos: $PROCESSED | Collab Repos Pulled: $COLLAB_PULLED | New GitHub: $CREATED_GH | New GitLab: $CREATED_GL"
