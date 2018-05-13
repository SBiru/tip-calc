class RestaurantsController < ApplicationController
  protect_from_forgery with: :exception
  skip_before_action :authenticate_user!
  skip_before_action :set_info

  def show
    if Restaurant.where(permalink: params[:id]).any?
      @restaurant = Restaurant.find_by(permalink: params[:id])
      @body_class = "submit-tips"
      @employee_distribution = @restaurant.employee_distributions.new
      @time = @restaurant.current_date
      session[:employeed_restaurant_id] = @restaurant.id
      session[:employeed_restaurant_permalink] = @restaurant.permalink

      gon.push({
        restaurant_inheritance_data: @restaurant.related_data_inheritance,
        time: @time
      })
    else
      render plain: "No such restaurant", status: 200
    end
  end
end
