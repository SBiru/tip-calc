class Api::EmployeeDistributionsController < Api::ApiController
  protect_from_forgery with: :exception
  before_action :authenticate_model!

  def remove_distribution
    calculation = Calculation.find(params[:calculation_id])
    distribution = calculation.employee_distributions.find_by(employee_id: params[:employee_id], position_type_id: params[:position_type_id])
    if distribution.destroy
      calculation.recalculate # TODO: move to model
      render json: true, status: 200
    else
      render json: distribution.errors, status: 422
    end 
  end

  def check_approval_status
    calculation = Calculation.find(params[:calculation_id])
    @employee_distribution = EmployeeDistribution.pending.find(params[:id])

    action = params[:approval_action] == "approve" ? "approve" : "decline"

    if @employee_distribution.send("#{action}!".to_sym, calculation)
      if @employee_distribution.persisted?
        render :show, status: 200
      else
        render json: { employee_distribution: { persisted: false } }, status: 200
      end
    else
      render json: { errors: @employee_distribution.errors.full_messages.join(", ") }, status: 422
    end
  end

  def change_employee
    calculation = Calculation.find(params[:calculation_id])
    distribution = calculation.employee_distributions.find(params[:employee_distribution_id])
    distribution.employee_id = params[:employee_id]

    if distribution.save
      render json: true, status: 200
    else
      render json: distribution.errors, status: 422
    end
  end

  def employee_distribution_params
    params.require(:employee_distributions).permit(:employees)
  end
end
