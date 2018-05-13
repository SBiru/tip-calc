class EmployeeDistributionsController < ApplicationController
  protect_from_forgery with: :exception
  skip_before_action :authenticate_user!
  skip_before_action :set_info

  def create
    short_params = employee_distribution_params.permit(:date, :area_type, :shift_type, :employee, :restaurant_id, :position_type, :team_number)

    if EmployeeDistribution.unscoped.where(short_params).any?
      ed = EmployeeDistribution.unscoped.where(short_params).first
      flash[:error] = "There already exists a record for #{ ed.employee.integrated_info }, #{ ed.date.to_date }, #{ ed.area_type.name.titleize }, #{ ed.shift_type.name.titleize }. Please see manager for more information."
    else
      @restaurant = Restaurant.find(employee_distribution_params[:restaurant_id])
      @employee_distribution = EmployeeDistribution.new(employee_distribution_params)
      @employee_distribution.date = employee_distribution_params[:date].in_time_zone(@restaurant.timezone)
      @employee_distribution.status = "pending"
      @employee_distribution.is_a_source_distribution = true
      if @employee_distribution.save
        flash[:notice] = "Thank you for submitting your Tips"
      else
        flash[:error] = @employee_distribution.errors.full_messages.join(", ")
      end
    end
    redirect_to :back
  end

  def employee_distribution_params
    params.require(:employee_distribution).permit(
      :date,
      :hours_worked,
      :cash_tips,
      :cc_tips,
      :sales_summ,
      :team_number,
      :area_type,
      :shift_type,
      :position_type,
      :employee,
      :restaurant_id
    )
  end
end
