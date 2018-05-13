class Api::CalculationsController < Api::ApiController
  protect_from_forgery with: :exception
  before_action :authenticate_model!
  before_action :authenticate_user!, only: [:destroy]

  def update
    calculation = Calculation.find(params[:calculationId])
    if data = calculation.update_calculation(params)
      render json: {
        distributions: data[:new_distributions],
        tip_outs: data[:tip_outs],
        calculation_params: data[:calculation_params]
      }, status: 200
    else
      render json: calculation.errors.full_messages.join(", "), status: 422
    end
  end

  def duplicate
    calculation = Calculation.find(params[:originalId])
    duplicated_calculation = calculation.duplicate(params[:positionTypeIds])
    render json: { duplicated_calculation_id: duplicated_calculation.id.to_s }, status: 200
  end

  def percent_variations 
    calculation = Calculation.find(params[:calculation_id])
    render json: {
      percent_variations: calculation.percent_variations
    }, status: 200
  end

  def destroy   
    calculation = Calculation.find(params[:id])
    if calculation.destroy
      render json: true, status: 200
    else
      render json: true, status: 422
    end
  end

  def check_calculation
    date = Time.strptime(params[:date], "%m/%d/%Y").to_date
    day_calc = @restaurant.day_calculations.find_or_create_by(date: date)

    calculations = Calculation.all.where(
      area_type_id: params[:area_type_id],
      shift_type_id: params[:shift_type_id],
      date: date
    )

    calculations = calculations.select{|f| !f.is_blank? }

    if day_calc.locked?
      render json: { locked: true, errors: "Day is locked." }, status: 422
    elsif !current_signed_model.has_access_to?(params[:area_type_id])
      render json: { has_no_access_to_area: true, errors: "Area is not available for you." }, status: 422
    else
      render json: { persisted: calculations.any? }, status: 200
    end
  end

  def check_existance
    if Calculation.where(id: params[:calculation_id]).present?
      render json: { persisted: true }, status: 200
    else
      render json: { persisted: false }, status: 422
    end
  end

  def employee_distribution_params
    params.require(:employee_distributions).permit(:employees)
  end
end
