Rails.application.routes.draw do
  defaults format: :json do
    post 'sign_in', to: 'sessions#sign_in'
    delete 'sign_out', to: 'sessions#sign_out'
    post 'forgot_password', to: 'sessions#forgot_password'

    post 'sign_up', to: 'accounts#create', as: :sign_up
    resources :accounts, except: :index do
      member do
        get 'activate/:token', to: 'accounts#activate', as: :activate
        get 'unlock/:token', to: 'accounts#unlock', as: :unlock
        patch 'reset_password/:token', to: 'accounts#reset_password', as: :reset_password
      end
    end
  end
end
