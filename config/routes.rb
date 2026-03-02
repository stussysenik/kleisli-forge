Rails.application.routes.draw do
  devise_for :users

  # API endpoints
  namespace :api do
    namespace :v1 do
      resources :components, only: [:create, :show] do
        member do
          get :vue
          get :svelte
          get :stream
        end
      end
    end
  end

  # Web interface
  resources :components, only: [:index, :new, :create, :show]
  resources :pipelines, only: [:show]

  # SSE streaming endpoint
  get "pipelines/:id/events", to: "pipelines#events", as: :pipeline_events

  root "components#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
