Rails.application.routes.draw do
  # Health check
  get "health", to: proc { [ 200, {}, [ "OK" ] ] }
  get "up" => "rails/health#show", as: :rails_health_check

  # OAuth 2.1 endpoints
  get  ".well-known/oauth-authorization-server", to: "oauth/metadata#authorization_server"
  get  ".well-known/oauth-protected-resource", to: "oauth/metadata#protected_resource"
  post "oauth/register", to: "oauth/clients#create"
  get  "oauth/register/:client_id", to: "oauth/clients#show", as: :oauth_client
  get  "oauth/authorize", to: "oauth/authorization#new", as: :oauth_authorize
  post "oauth/authorize", to: "oauth/authorization#create"
  post "oauth/token", to: "oauth/tokens#create"
  post "oauth/revoke", to: "oauth/revocation#create"

  # MCP (Model Context Protocol) endpoint
  post "mcp", to: "mcp#handle"

  # Onboarding (first user setup)
  get  "setup", to: "onboarding#new", as: :onboarding
  post "setup", to: "onboarding#create"

  # Authentication (Rails 8 generated)
  resource :session
  resources :passwords, param: :token

  # Account setup (for approved waitlist users)
  get  "setup-password/:token", to: "account_setup#edit", as: :edit_account_setup
  put  "setup-password/:token", to: "account_setup#update", as: :account_setup

  # Registration via invite
  get  "register/:token", to: "registrations#new", as: :register
  post "register/:token", to: "registrations#create"

  # Landing page (public) and Dashboard (authenticated)
  root "home#index"
  get "dashboard", to: "home#dashboard", as: :dashboard

  # Waitlist
  get  "waitlist", to: "waitlist#new", as: :new_waitlist
  post "waitlist", to: "waitlist#create", as: :waitlist
  get  "waitlist/thank-you", to: "waitlist#thank_you", as: :waitlist_thank_you

  # How To / Documentation
  get "how-to", to: "home#how_to", as: :how_to

  # Public share links (unauthenticated access)
  get "s/:token", to: "public_insights#show", as: :public_insight
  get "s/:token/files/*id", to: "public_insight_files#show", as: :public_insight_file, format: false

  # Organization members (read-only for all members)
  resources :members, only: [:index]

  # Insights
  resources :insight_items, param: :id do
    member do
      post :publish
      post :unpublish
      get :export
      post :enable_share
      post :disable_share
      post :regenerate_share_token
    end
    get "files/*id", to: "insight_item_files#show", as: :file, format: false
    resources :comments, only: [:create, :update, :destroy]
  end
  get "my-insights", to: "insight_items#my_insights", as: :my_insights

  # Profile
  resource :profile, only: [:show, :edit, :update] do
    post :regenerate_token
    get :export_all_insights
    post :import_insights
  end

  # Admin
  namespace :admin do
    resources :users, only: [ :index, :edit, :update, :destroy ]
    resources :invites, only: [ :index, :new, :create, :destroy ]
    resources :waitlist_entries, only: [ :index, :destroy ] do
      member do
        post :approve
      end
    end
  end

  # API
  namespace :api do
    namespace :v1 do
      resource :me, only: [:show], controller: "me"
      resources :tags, only: [:index]
      resources :insight_items, param: :id do
        member do
          post :publish
          post :unpublish
        end
        resources :files, only: [:destroy], controller: "insight_item_files"
      end
    end
  end
end
