class Api::ApiController < ApplicationController
  layout :false
  skip_before_action :verify_authenticity_token
  before_action :authenticate_model!
  
  before_action :set_info

  def set_info
    @restaurant = if current_signed_model.is_admin? && session[:admin_restaurant_id] && Restaurant.all.where(id: session[:admin_restaurant_id]).any?
      Restaurant.find(session[:admin_restaurant_id])
    else
      current_signed_model.try(:restaurant)
    end
  end
end
