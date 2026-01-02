Rails.application.routes.draw do
  # Health check
  get "health", to: proc { [ 200, {}, [ "OK" ] ] }
  get "up" => "rails/health#show", as: :rails_health_check

  # MCP (Model Context Protocol) endpoint
  post "mcp", to: "mcp#handle"

  # Onboarding (first user setup)
  get  "setup", to: "onboarding#new", as: :onboarding
  post "setup", to: "onboarding#create"

  # Authentication (Rails 8 generated)
  resource :session
  resources :passwords, param: :token

  # Registration via invite
  get  "register/:token", to: "registrations#new", as: :register
  post "register/:token", to: "registrations#create"

  # Landing page (public) and Dashboard (authenticated)
  root "home#index"
  get "dashboard", to: "home#dashboard", as: :dashboard

  # How To / Documentation
  get "how-to", to: "home#how_to", as: :how_to

  # Insights
  resources :insight_items, param: :id do
    member do
      post :publish
      post :unpublish
      get :export
    end
    get "files/*id", to: "insight_item_files#show", as: :file, format: false
    resources :comments, only: [:create, :update, :destroy]
  end
  get "my-insights", to: "insight_items#my_insights", as: :my_insights

  # Profile
  resource :profile, only: [:show, :edit, :update] do
    post :regenerate_token
    get :export_all_insights
  end

  # Admin
  namespace :admin do
    resources :users
    resources :invites, only: [ :index, :new, :create, :destroy ]
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
