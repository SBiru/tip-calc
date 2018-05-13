class Employees::PasswordsController < Devise::PasswordsController

  before_action :set_restaurant

  # POST /resource/password
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      flash[:notice] = "You will receive a password reset email in a few minutes if you have a TipMetric account under that email."
      redirect_to new_employee_password_path
    else
      flash[:notice] = resource.errors.full_messages.join(", ")
      redirect_to new_employee_password_path
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  def edit
    self.resource = resource_class.new
    set_minimum_password_length
    resource.reset_password_token = params[:reset_password_token]
  end

  # PUT /resource/password
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?

    if resource.errors.empty?
      resource.unlock_access! if unlockable?(resource)
      if Devise.sign_in_after_reset_password
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message!(:notice, flash_message)
        sign_in(resource_name, resource)
      else
        set_flash_message!(:notice, :updated_not_active)
      end
      redirect_to after_resetting_password_path_for(resource)
    else
      set_minimum_password_length
      render "/employees/passwords/edit"
    end
  end

  def set_restaurant
    if session[:employeed_restaurant_permalink]
      @restaurant = Restaurant.all.find_by(permalink: session[:employeed_restaurant_permalink])
    end
  end

  def after_sending_reset_password_instructions_path_for(resource_name)
    "/#{ @restaurant.permalink }"
  end

  def after_resetting_password_path_for(resource_name)
    "/#{ @restaurant.permalink }"
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