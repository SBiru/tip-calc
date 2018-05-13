module ApplicationHelper
  def date_total_by_format(date_total, money_type)
    if date_total.is_a?(Hash)
      "<span class='#{ money_type }'>
        <span class='given'>-#{ to_2_decimals(date_total[:given].try(:round, 2)) }</span>
        <span class='received'>+#{ to_2_decimals(date_total[:received].try(:round, 2)) }</span>
      </span>".html_safe
    else
      "<span class='#{ money_type }'>
        #{ to_2_decimals(date_total.try(:round, 2)) }
      </span>".html_safe
    end
  end

  def to_2_decimals(number=0)
    number ? sprintf('%.2f', number) : 0.00
  end

  def flash_class(level)
    case level
      when 'info' then "alert alert-info"
      when 'notice','success' then "alert alert-success"
      when 'error' then "alert alert-danger"
      when 'alert' then "alert alert-warning"
    end
  end

  def authenticate_model!
    employee_signed_in? ? authenticate_employee! : authenticate_user!
  end

  def current_signed_model
    employee_signed_in? ? current_employee : current_user
  end

  def build_params_from(calculation)
    params[:date] = calculation.date.strftime("%m/%d/%Y")
    params[:area_type_id] = calculation.area_type_id.to_s
    params[:shift_type_id] = calculation.shift_type_id.to_s
    params[:source_position_ids] = calculation.source_position_ids
    params[:teams_quantity] = calculation.teams_quantity
  end

  def before_calculation
    @body_class = "calculation"
    @calculation = Calculation.new
    gon.push({
      restaurant_inheritance_data: @restaurant.related_data_inheritance
    })
  end

  def get_calculation_data
    @body_class = "calculation"
    if params[:calculation_id]
      @calculation = @restaurant.calculations.find(params[:calculation_id])
      build_params_from(@calculation)
    else
      @calculation = Calculation.build_by(
        params[:area_type_id],
        params[:shift_type_id],
        params[:date],
        params[:teams_quantity],
        params[:source_position_ids],
        params[:existed_calculation_method],
        @restaurant
      )
      build_params_from(@calculation)
    end
    @calculation_exist = true
    @all_related_employees = @calculation.related_employees(false)
    @calculation_employees = @all_related_employees.sort_by{|k,v| v[:position_type_is_a_source] ? 1 : 0 }.reverse
    @restaurant_inheritance_data = @restaurant.related_data_inheritance

    @calculation_day_area_calculation = @calculation.day_area_calculation

    @calculation_employee_distributions = @calculation.employee_distributions.to_a

    # pending
    @calculation_pending_distributions = @calculation.pending_distributions

    # active areas and shifts and positions
    @restaurant_area_types_active = @restaurant.area_types.active.to_a
    @restaurant_shift_types_active = @restaurant.shift_types.active.to_a
    @restaurant_position_types_active = @restaurant.position_types.active.to_a

    # tip outs
    @calculation_received_tip_outs = @calculation.received_tip_outs.to_a
    @calculation_sender_tip_outs = @calculation.sender_tip_outs.to_a

    # total given tip outs
    @calculation_total_tip_outs_given_cc = @calculation_sender_tip_outs.map{|f| f.cc_summ }.compact.reduce(:+) || 0
    @calculation_total_tip_outs_given_cash = @calculation_sender_tip_outs.map{|f| f.cash_summ }.compact.reduce(:+) || 0

    # all areas and shifts
    @restaurant_area_types = @restaurant.area_types.to_a
    @restaurant_shift_types = @restaurant.shift_types.to_a

    gon.push({
      calculation_id: @calculation.id.to_s,
      calculation_params: params.merge({
        source_position_ids: @calculation.source_position_ids.map{|f| f.to_s }
      }),
      restaurant: {
        shifted_tip_outs_enabled: @restaurant.shifted_tip_outs_enabled
      },
      related_employees: @calculation.related_employees(true),
      all_related_employees: @all_related_employees,
      areas: @restaurant.area_types.select{|f| f != @calculation.area_type}.map{|f| {id: f.id.to_s, name: f.name}},
      shifts: @restaurant.shift_types.map{|f| {id: f.id.to_s, name: f.name}},
      restaurant_inheritance_data: @restaurant_inheritance_data
    })
  end

  def history_link
    case current_signed_model.class
    when User
      history_path
    when Employee
      employees_history_path
    end
  end

  def show_calculation_link
    case current_signed_model.class
    when User
      show_calculation_path
    when Employee
      employees_show_calculation_path
    end
  end
end
