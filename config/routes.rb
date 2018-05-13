Rails.application.routes.draw do
  devise_for :users, :controllers => { 
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  devise_for :employees, path: 'employees', :controllers => {
    registrations: "employees/registrations",
    sessions: "employees/sessions",
    passwords: "employees/passwords"
  }

  root 'application#home'
  get "dashboard" => "dashboard#dashboard"
  post "dashboard_post" => "dashboard#dashboard_post"
  get "setup" => "dashboard#setup"
  get "employee" => "dashboard#employee"
  get "calculation" => "dashboard#calculation"
  get "day_calculations/:id" => "dashboard#day_calculation"
  post "show_calculation" => "dashboard#show_calculation"
  get "show_calculation_get" => "dashboard#show_calculation_get"
  post "show_reports" => "dashboard#show_reports"
  get "set_restaurant" => "dashboard#set_restaurant"
  get "reports" => "dashboard#reports"
  get "restaurants" => "dashboard#restaurants"
  get "messages" => "dashboard#messages"
  get "subscribers" => "dashboard#subscribers"
  get "history" => "dashboard#history"
  get "billing" => "dashboard#billing"
  get "billing_user" => "dashboard#billing_user"

  get "terms" => "pages#terms"
  get "privacy" => "pages#privacy"

  namespace :api do
    resources :restaurants, only: [:update, :show]
    resources :area_types, only: [:create, :destroy, :update] do
      patch :reactivate
    end
    resources :shift_types, only: [:create, :destroy, :update] do
      patch :reactivate
    end
    resources :position_types, only: [:create, :destroy, :update] do
      patch :reactivate
    end
    resources :employees, only: [:create, :destroy, :update] do
      patch :reactivate
      collection do
        get :check_user
        patch :import_employees
        patch :add_position
      end
    end
    resources :calculations, only: [:update, :destroy] do
      get :percent_variations
      get :check_existance
      collection do
        get :check_calculation
        get :duplicate
      end
    end
    resources :employee_distributions, only: [:create] do
      collection do
        patch :update_distributions
        delete :remove_distribution
        patch :check_approval_status
        patch :change_employee
      end
    end
    resources :tip_outs, only: [:create, :destroy] do
      # collection do
      #   patch :update_tip_outs
      # end
    end

    resources :cards, only: [:create] do
      collection do
        patch :update
        delete :destroy
      end
    end

    resources :subscriptions, only: [:create] do
      collection do
        delete :destroy
      end
    end

    resources :day_calculations, only: [:update]

    resource :setup do
      collection do
        get :schedule_html
        get :workload_html
        patch :update_ps_relation
        patch :update_as_relation
      end
    end

    resources :subscribers, only: [:create]
    resources :messages, only: [:create]
  end

  namespace :employees do
    get "calculation" => "dashboard#calculation"
    post "show_calculation" => "dashboard#show_calculation"
    get "show_calculation_get" => "dashboard#show_calculation_get"
    get "history" => "dashboard#history"
    get "dashboard" => "dashboard#dashboard"
    get "reports" => "dashboard#reports"
    post "show_reports" => "dashboard#show_reports"
    post "dashboard_post" => "dashboard#dashboard_post"
  end

  get "/:id", to: "restaurants#show"
  resources :employee_distributions, only: [:create]
end
