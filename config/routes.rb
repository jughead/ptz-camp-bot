require 'sidekiq/web'
Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations',
  }

  authenticate :user, lambda{ |u| u.admin? } do
    get :admin, to: 'admin/site#home'

    namespace :admin do
      mount Sidekiq::Web => '/sidekiq'
      resources :messages, only: [:index, :create, :new]
      resources :camps do
        member do
          get :dashboard
          get :badges
        end
        resources :delegations
        resources :day_schedules, only: [:index, :edit, :update]
        resources :participants
        resources :pages, except: [:show]
        resources :teams, except: [:show]
        resources :events, except: [:show]
      end
      resources :pages, except: [:show]
      resources :public_files, path: :files, except: [:show]
    end
  end

  resources :camps, path: '', param: :slug, only: [] do
    resource :schedule, controller: :schedule, only: :show
    resources :participants, only: [:new, :index, :create, :edit, :update, :show]
    resources :teams, only: [:index]
    resources :events, only: [:show, :index] do
      member do
        post :opt_in
        post :opt_out
        get :participants
      end
    end
    resources :pages, path: '', param: :slug, only: :show
  end

  resources :camps, path: '', param: :slug, only: :show, constraints: CampConstraint.new
  resources :pages, path: '', param: :slug, only: :show, constraints: GlobalPageConstraint.new

  root to: 'site#home'
end
