class Api::EmployeesController < Api::ApiController
  protect_from_forgery with: :exception
  before_action :authenticate_user!

  def create
    @employee = @restaurant.employees.new(employee_params)
    if @employee.save
      render :show, status: 200
    else
      render json: @employee.errors.full_messages.join(", "), status: 422
    end
  end

  def destroy
    @employee = @restaurant.employees.find(params[:id])
    if response = @employee.deactivate_with_position(params[:position_type_id])
      render json: {
        employee_status: response
      }, status: 200
    else
      render json: @employee.errors.full_messages.join(", "), status: 422
    end
  end

  def update
    @employee = @restaurant.employees.find(params[:id])
    @employee.allowed_area_ids = [] if params[:allowed_area_ids].blank?
    if @employee.update(employee_params)
      render json: {
        allowed_areas: @employee.available_areas_json
      }, status: 200
    else
      render json: @employee.errors.full_messages.join(", "), status: 422
    end
  end

  def add_position
    @employee = @restaurant.employees.find_by(emp_id: params[:empId])
    @position_type = @restaurant.position_types.find_by(name: params[:position])
    if (@employee.position_types << @position_type ) && (@position_type.employees << @employee)
      render :show, status: 200
    else
      render json: @employee.errors.full_messages.join(", "), status: 422
    end
  end

  def reactivate
    @employee = @restaurant.employees.find(params[:employee_id])
    if @employee.activate
      render json: true, status: 200
    else
      render json: @employee.errors.full_messages.join(", "), status: 422
    end
  end

  def check_user
    @employee = @restaurant.employees.where(emp_id: params[:empId]).first
    if @employee
      render json: {
        employee: @employee
      }, status: 200
    else
      render json: false, status: 422
    end
  end

  def import_employees
    source_position = @restaurant.position_types.find(params[:sourceId])
    receiver_position = @restaurant.position_types.find(params[:receiverId])

    source_position.employees.each do |employee|
      employee.position_types << receiver_position
      receiver_position.employees << employee
    end

    render json: true, status: 200
  end

  def employee_params
    params.require(:employee).permit(:first_name, :last_name, :emp_id, allowed_area_ids: [], position_type_ids: [])
  end
end
