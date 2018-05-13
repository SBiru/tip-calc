class Employees::RegistrationsController < Devise::RegistrationsController

  before_action :set_restaurant

  def set_restaurant
    if session[:employeed_restaurant_permalink]
      @restaurant = Restaurant.all.find_by(permalink: session[:employeed_restaurant_permalink])
    end
  end

  # POST /resource
  def create
    resource = Employee.find(params[:employee_id])

    if resource.registered?
      flash[:notice] = "User already registered. Please log in."
      respond_with resource, location: after_inactive_sign_up_path_for(resource)
    else
      if params[:employee][:password_confirmation] != params[:employee][:password]
        flash[:error] = "Password and password confirmation do not match."
        redirect_to :back
      elsif params[:employee][:password].length < 6
        flash[:error] = "Password should be at least 6 characters."
        redirect_to :back
      elsif @restaurant.employees.where(email: params[:employee][:email]).any?
        flash[:error] = "Email is already taken."
        redirect_to :back
      else
        resource.update(sign_up_params)
        resource.save
        yield resource if block_given?
        if resource.persisted?
          if resource.active_for_authentication?
            set_flash_message! :notice, :signed_up
            sign_up(resource_name, resource)
            respond_with resource, location: after_sign_up_path_for(resource)
          else
            set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
            expire_data_after_sign_in!
            respond_with resource, location: after_inactive_sign_up_path_for(resource)
          end
        else
          clean_up_passwords resource
          set_minimum_password_length
          respond_with resource
        end
      end
    end
  end

  # PUT /resource
  # We need to use a copy of the resource because we don't want to change
  # the current user in place.
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?
    if resource_updated
      if is_flashing_format?
        flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ?
          :update_needs_confirmation : :updated
        set_flash_message :notice, flash_key
      end
      bypass_sign_in resource, scope: resource_name
      respond_with resource, location: after_update_path_for(resource)
    else
      clean_up_passwords resource
      respond_with resource
    end
  end

  protected

  def after_update_path_for(resource)
    employees_dashboard_path
  end

  def after_sign_in_path_for(resource)
    employees_dashboard_path
  end

  def after_sign_up_path_for(resource)
    employees_dashboard_path
  end
end