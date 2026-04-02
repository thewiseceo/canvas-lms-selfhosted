#!/usr/bin/env bash
# =============================================================================
# Canvas LMS — Create or Reset Admin User
# Usage: ./scripts/create-admin.sh <email> <password> [display_name]
# Example: ./scripts/create-admin.sh admin@school.edu "P@ssw0rd!" "Site Admin"
# =============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

EMAIL="${1:-}"
PASSWORD="${2:-}"
NAME="${3:-Administrator}"

[[ -n "$EMAIL" ]]    || { echo "Usage: $0 <email> <password> [name]"; exit 1; }
[[ -n "$PASSWORD" ]] || { echo "Usage: $0 <email> <password> [name]"; exit 1; }

echo "Creating/resetting admin user: $EMAIL"

docker compose exec canvas bundle exec rails runner "
email    = '${EMAIL}'
password = '${PASSWORD}'
name     = '${NAME}'

user = User.find_by_email(email)

  if user.nil?
user = User.create!(name: name, workflow_state: 'registered')
    user.pseudonyms.create!(
      unique_id: email,
      password: password,
      password_confirmation: password,
      account: Account.site_admin
)
puts \"Created new user: #{email}\"
else
pseudonym = user.pseudonyms.find_by(unique_id: email) ||
                user.pseudonyms.first
pseudonym.update!(password: password, password_confirmation: password)
puts \"Reset password for existing user: #{email}\"
end

unless Account.site_admin.account_users.where(user: user).exists?
    Account.site_admin.account_users.create!(
      user: user,
role: Role.get_built_in_role('AccountAdmin')
)
puts \"Granted site admin role to: #{email}\"
else
    puts \"User already has site admin role.\"
end
" RAILS_ENV=production

echo "Done. Log in at your Canvas domain with: $EMAIL"
