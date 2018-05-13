class Api::CardsController < Api::ApiController
  protect_from_forgery with: :exception
  before_action :authenticate_user!

  def create
    card = @restaurant.user.add_source(params[:token])
    if card
      render json: card, status: 200
    else
      render json: false, status: 422
    end
  end

  def update
    if @restaurant.user.set_default_card(params[:card_id])
      render json: true, status: 200
    else
      render json: false, status: 422
    end
  end

  def destroy   
    if @restaurant.user.delete_card(params[:card_id])
      render json: true, status: 200
    else
      render json: false, status: 422
    end
  end
end