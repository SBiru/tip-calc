class Api::AreaTypesController < Api::ApiController
  protect_from_forgery with: :exception
  before_action :authenticate_user!

  def create
    @area_type = @restaurant.area_types.new(area_type_params)
    if @area_type.save
      render :show, status: 200
    else
      render plain: @area_type.errors.full_messages.join(", "), status: 422
    end
  end

  def destroy
    @area_type = @restaurant.area_types.find(params[:id])
    if @area_type.deactivate
      render json: {
        persisted: @area_type.persisted?
      }, status: 200
    else
      render plain: @area_type.errors.full_messages.join(", "), status: 422
    end
  end

  def update
    @area_type = @restaurant.area_types.find(params[:id])
    if @area_type.update(area_type_params)
      render json: true, status: 200
    else
      render plain: @area_type.errors.full_messages.join(", "), status: 422
    end
  end

  def reactivate
    @area_type = @restaurant.area_types.find(params[:area_type_id])
    if @area_type.activate
      render json: true, status: 200
    else
      render plain: @area_type.errors.full_messages.join(", "), status: 422
    end
  end

  def area_type_params
    params.require(:area_type).permit(:name)
  end
end
