#!/usr/bin/env bash
# =============================================================================
# Canvas LMS — Admin Rails Console
# Opens an interactive Ruby on Rails console inside the Canvas container
# with full database access and admin context.
# Usage: ./scripts/admin-console.sh
# =============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "Opening Canvas Rails admin console..."
echo "  - Type 'exit' or press Ctrl+D to quit."
echo "  - Example: Account.site_admin.account_users.map { |u| u.user.email }"
echo ""

docker compose exec canvas bundle exec rails console RAILS_ENV=production
