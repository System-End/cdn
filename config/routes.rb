Rails.application.routes.draw do
  namespace :admin do
    get "search", to: "search#index"
    resources :users, only: [ :show, :update, :destroy ]
    resources :uploads, only: [ :destroy ]
    resources :api_keys, only: [ :destroy ]
  end

  delete "/logout", to: "sessions#destroy", as: :logout
  get "/login", to: "static_pages#login", as: :login
  root "static_pages#home", as: :root
  post "/auth/hack_club", as: :hack_club_auth
  get "/auth/hack_club/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"

  resources :uploads, only: [ :index, :create, :update, :destroy ] do
    collection do
      delete :destroy_batch
    end
  end

  resources :api_keys, only: [ :index, :create, :destroy ]

  namespace :api do
    namespace :v4 do
      get "me", to: "users#show"
      post "upload", to: "uploads#create"
      post "uploads", to: "uploads#create_batch"
      post "upload_from_url", to: "uploads#create_from_url"
      patch "uploads/:id/rename", to: "uploads#rename", as: :upload_rename
      delete "uploads/batch", to: "uploads#destroy_batch", as: :uploads_batch_delete
      post "revoke", to: "api_keys#revoke"
    end
  end

  get "/docs", to: redirect("/docs/getting-started")
  get "/docs/:id", to: "docs#show", as: :doc

  get "up" => "rails/health#show", as: :rails_health_check

  get "/rescue", to: "external_uploads#rescue", as: :rescue_upload

  namespace :slack do
    post "events", to: "events#create"
  end

  get "/:id/*filename", to: "external_uploads#show", constraints: { id: /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/ }, as: :external_upload
end
