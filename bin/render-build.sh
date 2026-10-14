#!/usr/bin/env bash
set -euo pipefail

export RAILS_ENV=production
bundle install
# assets:precompile includes the tailwindcss-rails build hook.
# This flag applies only to this build command, never to the runtime server.
SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile
