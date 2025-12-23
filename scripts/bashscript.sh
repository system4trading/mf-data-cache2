#!/bin/bash
# =====================================================
# Hybrid MF Analyzer – Install, Dev Run & Data Sync
# =====================================================

set -e

APP_REPO="mf-analytics"
DATA_REPO="mf-data-cache"

# Change these to your GitHub repos
DATA_REPO_GIT="https://github.com/YOURNAME/mf-data-cache.git"

NODE_VERSION_REQUIRED=18

echo "-----------------------------------------"
echo "Hybrid MF Analyzer – Setup & Data Pipeline"
echo "-----------------------------------------"

# -------------------------------
# Check Node.js
# -------------------------------
if ! command -v node &> /dev/null
then
  echo "❌ Node.js not installed"
  exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//')
NODE_MAJOR=$(echo $NODE_VERSION | cut -d. -f1)

if [ "$NODE_MAJOR" -lt "$NODE_VERSION_REQUIRED" ]; then
  echo "❌ Node.js v18+ required"
  exit 1
fi

echo "✅ Node.js version OK: $NODE_VERSION"

# -------------------------------
# Install frontend dependencies
# -------------------------------
if [ -f "package.json" ]; then
  echo "📦 Installing frontend dependencies..."
  npm install
fi

# -------------------------------
# Clone data cache repo if missing
# -------------------------------
if [ ! -d "$DATA_REPO" ]; then
  echo "📥 Cloning mf-data-cache repo..."
  git clone $DATA_REPO_GIT
fi

# -------------------------------
# Install data repo dependencies
# -------------------------------
cd $DATA_REPO

if [ ! -f "package.json" ]; then
cat <<EOF > package.json
{
  "type": "module",
  "dependencies": {
    "node-fetch": "^3.3.2"
  }
}
EOF
fi

npm install

# -------------------------------
# Fetch AMFI NAV data
# -------------------------------
echo "📈 Fetching AMFI NAV historical data..."
node scripts/fetch_amfi.js

# -------------------------------
# Fetch Nifty 50 data
# -------------------------------
echo "📊 Fetching Nifty 50 historical data..."
node scripts/fetch_nifty.js

# -------------------------------
# Build category averages
# -------------------------------
echo "📊 Building category averages..."
node scripts/build_category_avg.js

# -------------------------------
# Commit & push data
# -------------------------------
echo "🚀 Pushing updated data to GitHub..."


git config user.name "amfi-bot"
git config user.email "bot@github.com"
git add .
git commit -m "Daily MF & Nifty data update" || echo "ℹ️ No changes to commit"
git push
