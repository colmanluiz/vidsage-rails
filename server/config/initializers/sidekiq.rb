require 'sidekiq'
require 'sidekiq/web'

# Configure Sidekiq server
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

# Configure Sidekiq client
Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

# Configure ActiveJob to use Sidekiq
Rails.application.config.active_job.queue_adapter = :sidekiq

Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  username == 'admin' && password == 'password'
end