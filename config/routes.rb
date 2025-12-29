Rails.application.routes.draw do
  # Health check
  get "health", to: proc { [ 200, {}, [ "OK" ] ] }
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication (Rails 8 generated)
  resource :session
  resources :passwords, param: :token

  # Registration via invite
  get  "register/:token", to: "registrations#new", as: :register
  post "register/:token", to: "registrations#create"

  # Dashboard
  root "home#index"

  # Reports
  resources :reports, param: :id do
    member do
      post :publish
      post :unpublish
    end
    get "files/*id", to: "report_files#show", as: :file, format: false
  end
  get "my-reports", to: "reports#my_reports", as: :my_reports

  # Profile
  resource :profile, only: [:show, :edit, :update] do
    post :regenerate_token
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
      resources :reports, param: :id do
        member do
          post :publish
          post :unpublish
        end
        resources :files, only: [:destroy], controller: "report_files"
      end
    end
  end
end
