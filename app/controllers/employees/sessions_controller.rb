class Employees::SessionsController < Devise::SessionsController

  before_action :set_restaurant

  # POST /resource/sign_in
  def create
    e = Employee.where(email: params[:employee][:email]).first
    if e && e.valid_password?(params[:employee][:password])
      set_flash_message!(:notice, :signed_in)
      sign_in(:employee, e)
      redirect_to employees_dashboard_path
    elsif e
      flash[:error] = "Password is incorrect."
      redirect_to :back
    else
      flash[:error] = "Employee doesn't exist"
      redirect_to :back
    end
  end

  def set_restaurant
    if session[:employeed_restaurant_permalink]
      @restaurant = Restaurant.all.find_by(permalink: session[:employeed_restaurant_permalink])
    end
  end

  def after_sign_in_path_for(resource)
    employees_dashboard_path
  end

  def after_sign_up_path_for(resource)
    employees_dashboard_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end