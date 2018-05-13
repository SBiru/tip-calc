class Employees::EmployeesController < ActionController::Base
  include ApplicationHelper
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  layout false, only: [:home]

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password, :name])
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :password, :name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:email, :password, :password_confirmation, :current_password, :name])
  end

  def after_sign_in_path_for(resource)
    employees_dashboard_path
  end

  def after_sign_up_path_for(resource)
    employees_dashboard_path
  end
end
