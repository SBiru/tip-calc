class Api::RestaurantsController < Api::ApiController
  protect_from_forgery with: :exception
  before_action :authenticate_user!

  def update
    if @restaurant.update(restaurant_params)
      render :show, status: 200
    else
      render json: @restaurant.errors.full_messages.join(", "), status: 422
    end
  end

  def restaurant_params
    params.require(:restaurant).permit(:name, :timezone, :top_employees_is_shown)
  end
end
