class ApplicationController < ActionController::API
  # API-only controller - no CSRF protection needed
  # No sessions, no cookies, just JSON responses
end
