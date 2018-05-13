class Api::DayCalculationsController < Api::ApiController
  protect_from_forgery with: :exception

  def update
    day_calculation = DayCalculation.find(params[:id])
    if day_calculation.toggle_lock_status(day_calculation_params.merge(modifier: current_user))
      render json: {
        day_calculation_id: day_calculation.id.to_s,
        day_calculation_locked: day_calculation.locked
      }, status: 200
    else
      render json: false, status: 422
    end
  end

  private

  def day_calculation_params
    params.require(:day_calculation).permit(:locked)
  end
end
