class Api::PositionTypesController < Api::ApiController
  protect_from_forgery with: :exception
  before_action :authenticate_user!

  def create
    @position_type = @restaurant.position_types.new(position_type_params)
    if @position_type.save
      render :show, status: 200
    else
      render plain: @position_type.errors.full_messages.join(", "), status: 422
    end
  end

  def destroy
    @position_type = @restaurant.position_types.find(params[:id])
    if @position_type.deactivate
      render json: {
        persisted: @position_type.persisted?
      }, status: 200
    else
      render plain: @position_type.errors.full_messages.join(", "), status: 422
    end
  end

  def update
    @position_type = @restaurant.position_types.find(params[:id])
    if @position_type.update(position_type_params)
      render json: true, status: 200
    else
      render plain: @position_type.errors.full_messages.join(", "), status: 422
    end
  end

  def reactivate
    @position_type = @restaurant.position_types.find(params[:position_type_id])
    if @position_type.activate
      render json: true, status: 200
    else
      render plain: @position_type.errors.full_messages.join(", "), status: 422
    end
  end

  def position_type_params
    params.require(:position_type).permit(:name)
  end
end
