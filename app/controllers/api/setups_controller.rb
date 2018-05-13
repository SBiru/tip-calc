class Api::SetupsController < Api::ApiController
  protect_from_forgery with: :exception
  before_action :authenticate_user!

  def schedule_html
    render file: "dashboard/setup/_schedule", layout: false
  end

  def workload_html
    render file: "dashboard/setup/_workload", layout: false
  end

  def update_ps_relation
    position = @restaurant.position_types.find(params[:position_type_id])
    shift = @restaurant.shift_types.find(params[:shift_type_id])
    area = @restaurant.area_types.find(params[:area_type_id])

    as = AreaShift.where(area_type_id: params[:area_type_id], shift_type_id: params[:shift_type_id]).first

    if params[:checked] == "true"
      position.area_shifts << as
      as.position_types << position
    else
      position.area_shifts.delete(as)
      as.position_types.delete(position)
    end

    if position.save && as.save
      render json: true, status: 200
    else
      render json: false, status: 422
    end
  end


  def update_as_relation
    area_shift = AreaShift.where(area_type_id: params[:area_type_id], shift_type_id: params[:shift_type_id]).first
    if area_shift.toggle_day(params[:day], params[:checked])
      render json: true, status: 200
    else
      render json: false, status: 422
    end
  end
end
