#!/usr/bin/env bash
# =============================================================================
# Canvas LMS Self-Hosted — First-Time Setup Script
# Run once after configuring .env and config/*.yml files
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

info "Running pre-flight checks..."
[[ -f ".env" ]] || error ".env not found. Copy .env.example to .env and fill in all values."

for cfg in config/database.yml config/cache_store.yml config/outgoing_mail.yml \
           config/security.yml config/dynamic_settings.yml; do
             [[ -f "$cfg" ]] || error "$cfg not found. Copy the matching .example file."
             done

             command -v docker         >/dev/null 2>&1 || error "Docker is not installed."
             command -v docker         >/dev/null 2>&1 || error "Docker Compose v2 is not installed."

             # shellcheck disable=SC1091
             source .env

             info "Pulling Docker images..."
             docker compose pull

             info "Starting PostgreSQL and Redis..."
             docker compose up -d postgres redis
             info "Waiting for PostgreSQL to be ready..."
             docker compose exec -T postgres \
               bash -c "until pg_isready -U \"$POSTGRES_USER\" -d \"$POSTGRES_DB\"; do sleep 2; done"

               info "Creating and migrating database..."
               docker compose run --rm canvas bundle exec rake db:create db:migrate RAILS_ENV=production

               info "Seeding database (this may take a few minutes)..."
               docker compose run --rm canvas bundle exec rake db:seed_fu RAILS_ENV=production

               info "Compiling front-end assets (10-20 minutes on first run)..."
               docker compose run --rm canvas bundle exec rake canvas:compile_assets RAILS_ENV=production

               info "Creating admin user: ${CANVAS_ADMIN_EMAIL}"
               docker compose run --rm canvas bundle exec rails runner "
                 user = User.create!(name: '${CANVAS_ADMIN_NAME}', workflow_state: 'registered')
                   user.pseudonyms.create!(
                       unique_id: '${CANVAS_ADMIN_EMAIL}',
                           password: '${CANVAS_ADMIN_PASSWORD}',
                               password_confirmation: '${CANVAS_ADMIN_PASSWORD}',
                                   account: Account.site_admin
                                     )
                                       Account.site_admin.account_users.create!(
                                           user: user,
                                               role: Role.get_built_in_role('AccountAdmin')
                                                 )
                                                   puts 'Admin user created.'
                                                   " RAILS_ENV=production

                                                   info "Starting all Canvas services..."
                                                   docker compose up -d

                                                   info "Setup complete! Visit https://${CANVAS_DOMAIN} and log in with ${CANVAS_ADMIN_EMAIL}"
