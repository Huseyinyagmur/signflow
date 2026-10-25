Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "templates/:template_id/versions/:id", to: "template_versions#show"
      resources :drafts, only: %i[create show]
    end
  end
  root "pages#home"
  resources :ai_contracts, only: %i[new create show] do
    post :message, on: :member
    post :draft, on: :member
  end
  resource :session, only: %i[new create show destroy]
  resource :registration, only: %i[new create]
  resources :agent_credentials, only: %i[index create] do
    post :revoke, on: :member
  end
  get "dashboard", to: "dashboard#show"
  resources :documents, except: :destroy do
    post :send_for_signature, on: :member
  end
  resources :templates, except: :destroy do
    post :add_examples, on: :collection
    get :history, on: :member
    resources :documents, only: %i[new create], controller: "template_documents" do
      post :preview, on: :collection
    end
  end
  get "sign", to: "signing#show", as: :signing
  post "sign/access", to: "signing#access", as: :signing_access
  post "sign", to: "signing#create"
  get "sign/complete", to: "signing#complete", as: :signing_complete
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
