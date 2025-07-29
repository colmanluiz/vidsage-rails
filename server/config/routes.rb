require 'sidekiq/web'

Rails.application.routes.draw do
  # Sidekiq Web UI with basic auth for development
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    # Secure but memorable for development
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV.fetch('SIDEKIQ_USERNAME', 'admin'))) &
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV.fetch('SIDEKIQ_PASSWORD', 'password')))
  end if Rails.env.production?

  mount Sidekiq::Web => '/sidekiq'

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      resources :videos, only: [:index, :show, :create] do
        member do
          post :query
          get :status
        end
      end
    end
  end

  # Root API info
  root to: proc { [200, {}, ['VidSage API - Video transcription and RAG system']] }
end
