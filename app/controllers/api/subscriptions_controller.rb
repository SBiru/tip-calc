class Api::SubscriptionsController < Api::ApiController
  protect_from_forgery with: :exception
  before_action :authenticate_user!

  def create
    if @restaurant.user.subscribe(params)
      render json: true, status: 200
    else
      render json: false, status: 422
    end
  end

  def destroy   
    if @restaurant.user.unsubscribe(params[:subscription_plan])
      render json: true, status: 200
    else
      render json: false, status: 422
    end
  end
end