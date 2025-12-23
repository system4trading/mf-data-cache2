#!/bin/bash
set -e

APP_REPO="mf-analytics"
DATA_REPO="mf-data-cache"

DATA_REPO_GIT="https://github.com/system4trading/mf-data-cache.git"

NODE_VERSION_REQUIRED=18

echo "Hybrid MF Analyzer – Setup & Data Pipeline"

# Check Node.js
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

# Install frontend deps if present
if [ -f "package.json" ]; then
  echo "📦 Installing frontend dependencies..."
  npm install
fi

# Clone data cache repo if missing (you may want to change this if you're already in the data repo)
if [ ! -d "$DATA_REPO" ]; then
  echo "📥 Cloning mf-data-cache repo..."
  git clone "$DATA_REPO_GIT"
fi

cd "$DATA_REPO"

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

echo "📈 Fetching AMFI NAV historical data..."
node scripts/fetch_amfi.js

echo "📊 Fetching Nifty 50 historical data..."
node scripts/fetch_nifty.js

echo "📊 Building category averages..."
node scripts/build_category_avg.js

echo "🚀 Pushing updated data to GitHub..."
git config user.name "amfi-bot"
git config user.email "bot@github.com"
git add .
git commit -m "Daily MF & Nifty data update" || echo "ℹ️ No changes to commit"
git push

# Do not run frontend dev server inside CI. Remove or guard this in local use.
# cd ..
# npm run dev
