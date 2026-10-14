#!/usr/bin/env bash
set -euo pipefail

export RAILS_ENV=production
: "${DATABASE_URL:?Set DATABASE_URL to the PostgreSQL internal URL}"
: "${RAILS_MASTER_KEY:?Set RAILS_MASTER_KEY in Render, never in the repository}"
if [[ -n "${SECRET_KEY_BASE_DUMMY:-}" ]]; then
  echo "SECRET_KEY_BASE_DUMMY is build-only; remove it from runtime environment." >&2
  exit 1
fi

# Works without a paid pre-deploy command. Failure prevents Puma from starting.
# No db:create, schema load, seed, reset or SQLite conversion is performed here.
bundle exec rails db:migrate
exec bundle exec puma -C config/puma.rb
