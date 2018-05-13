class Api::ShiftTypesController < Api::ApiController
  protect_from_forgery with: :exception
  before_action :authenticate_user!

  def create
    @shift_type = @restaurant.shift_types.new(shift_type_params)
    if @shift_type.save
      render :show, status: 200
    else
      render plain: @shift_type.errors.full_messages.join(", "), status: 422
    end
  end

  def destroy
    @shift_type = @restaurant.shift_types.find(params[:id])
    if @shift_type.deactivate
      render json: {
        persisted: @shift_type.persisted?
      }, status: 200
    else
      render plain: @shift_type.errors.full_messages.join(", "), status: 422
    end
  end

  def update
    @shift_type = @restaurant.shift_types.find(params[:id])
    if @shift_type.update(shift_type_params)
      render json: true, status: 200
    else
      render plain: @shift_type.errors.full_messages.join(", "), status: 422
    end
  end

  def reactivate
    @shift_type = @restaurant.shift_types.find(params[:shift_type_id])
    if @shift_type.activate
      render json: true, status: 200
    else
      render plain: @shift_type.errors.full_messages.join(", "), status: 422
    end
  end

  def shift_type_params
    params.require(:shift_type).permit(:name)
  end
end
