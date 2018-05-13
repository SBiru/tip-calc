class ApplicationController < ActionController::Base
  include ApplicationHelper
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :log_name

  layout false, only: [:home]

  def home
    @body_class = "landing-page"
    @subscriber = Subscriber.new
    @message = Message.new
  end

  def log_name
    if current_user
      date = Time.zone.now.strftime("%Y-%m-%dT%H:%M:%S")
      Rails.logger.info "I, [#{ date }.MANUAL #SYST]  INFO -- -----------------------------------------------"
      Rails.logger.info "I, [#{ date }.MANUAL #SYST]  INFO -- Currnet user is: #{ current_user.try(:id) } / #{ current_user.try(:email)}"
      Rails.logger.info "I, [#{ date }.MANUAL #SYST]  INFO -- -----------------------------------------------"
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password, :name])
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :password, :name, :registered])
    devise_parameter_sanitizer.permit(:account_update, keys: [:email, :password, :password_confirmation, :current_password, :name])
  end

  def after_sign_in_path_for(resource)
    dashboard_path
  end

  def after_sign_up_path_for(resource)
    dashboard_path
  end
end
