class Employees::DashboardController < Employees::EmployeesController
  layout "employee"

  before_action :authenticate_employee!
  before_action :set_info

  def dashboard
    @body_class = "dashboard"
    @dashboard_scope = "employees"
    @dashboard_post_url_scoped = employees_dashboard_post_path
    @show_rating = @restaurant.top_employees_is_shown
    # Setting day, monday and 1th of the month

    if params[:date].present?
      begin
        day = Time.strptime(params[:date], "%m/%d/%Y").to_date
      rescue
        day = @restaurant.current_time.to_date
        params[:date] = day.strftime("%m/%d/%Y")
        flash.now[:error] = "Error: please enter date in the format  \"MM/DD/YYYY - \"09/01/2017\""
      end
    else
      day = @restaurant.current_time.to_date
      params[:date] = day.strftime("%m/%d/%Y")
    end

    day_number = (day.wday + 6)%7 + 1
    monday = day - (day_number - 1).days
    first_of_month = day - (day.mday - 1).days

    # Main sales blocks

    current_employee_day_distr = @restaurant.employee_distributions.where(calculation_date: day, employee_id: current_employee.id)
    current_employee_week_distr = @restaurant.employee_distributions.where(calculation_date: monday..day, employee_id: current_employee.id)

    @cc_day = current_employee_day_distr.collect{|f| f.cc_tips_distr_final }.compact.reduce(:+).try(:round, 2) || 0
    @cc_week = current_employee_week_distr.collect{|f| f.cc_tips_distr_final }.compact.reduce(:+).try(:round, 2) || 0

    @cash_day = current_employee_day_distr.collect{|f| f.cash_tips_distr_final }.compact.reduce(:+).try(:round, 2) || 0
    @cash_week = current_employee_week_distr.collect{|f| f.cash_tips_distr_final }.compact.reduce(:+).try(:round, 2) || 0

    @total_day = current_employee_day_distr.collect{|f| f.cc_tips_distr_final + f.cash_tips_distr_final }.compact.reduce(:+).try(:round, 2) || 0
    @total_week = current_employee_week_distr.collect{|f| f.cc_tips_distr_final + f.cash_tips_distr_final }.compact.reduce(:+).try(:round, 2) || 0

    @sales_day = current_employee_day_distr.collect{|f| f.sales_summ }.compact.reduce(:+).try(:round, 2) || 0
    @sales_week = current_employee_week_distr.collect{|f| f.sales_summ }.compact.reduce(:+).try(:round, 2) || 0

    # Data for employees list

    if @show_rating

    emp_distrs_day = @restaurant.employee_distributions.where(calculation_date: day, is_a_source_distribution: true)
    emp_distrs_week = @restaurant.employee_distributions.where(calculation_date: monday..day, is_a_source_distribution: true)
    emp_distrs_month = @restaurant.employee_distributions.where(calculation_date: first_of_month..day, is_a_source_distribution: true)

    employees_data = emp_distrs_month.group_by{|f| f.employee_id }

    @employees = employees_data.map do |id, data|
      emp_distrs_day_for_employee = emp_distrs_day.where(employee_id: id)
      emp_distrs_week_for_employee = emp_distrs_week.where(employee_id: id)
      emp_distrs_month_for_employee = emp_distrs_month.where(employee_id: id)
      
      day_tips = emp_distrs_day_for_employee.collect{|empdistr| empdistr.total_collected_tips }.inject(&:+) || 0
      week_tips = emp_distrs_week_for_employee.collect{|empdistr| empdistr.total_collected_tips }.inject(&:+) || 0
      month_tips = emp_distrs_month_for_employee.collect{|empdistr| empdistr.total_collected_tips }.inject(&:+) || 0

      sales_day_summ = emp_distrs_day_for_employee.collect{|empdistr| empdistr.sales_summ }.inject(&:+) || 0
      sales_week_summ = emp_distrs_week_for_employee.collect{|empdistr| empdistr.sales_summ }.inject(&:+) || 0
      sales_month_summ = emp_distrs_month_for_employee.collect{|empdistr| empdistr.sales_summ }.inject(&:+) || 0

      tips_per_sales_day_summ = sales_day_summ == 0 || day_tips == 0 ? 0 : day_tips/sales_day_summ
      tips_per_sales_week_summ = sales_week_summ == 0 || week_tips == 0 ? 0 : week_tips/sales_week_summ
      tips_per_sales_month_summ = sales_month_summ == 0 || month_tips == 0 ? 0 : month_tips/sales_month_summ

      {
        employee: @restaurant.employees.find(id),
        tips_collected_day: day_tips.round(2),
        tips_collected_week: week_tips.round(2),
        tips_collected_month: month_tips.round(2),
        
        sales_day: sales_day_summ.round(2),
        sales_week: sales_week_summ.round(2),
        sales_month: sales_month_summ.round(2),
        
        tips_per_sales_day: (tips_per_sales_day_summ * 100).round(2),
        tips_per_sales_week: (tips_per_sales_week_summ * 100).round(2),
        tips_per_sales_month: (tips_per_sales_month_summ * 100).round(2)

      }
    end

    @employees = @employees.sort_by{|e| e[:tips_collected] }.reverse
    end

    render "shared/dashboard"
  end

  def reports
    @body_class = "reports"
    @show_only_current_employee = current_employee
    @show_reports_url_scoped = employees_show_reports_path
    @show_reports_scope = "employees"
    render "/dashboard/reports"
  end

  def history
    @body_class = "history"
    @history_date_data = @restaurant.filled_calculations.in(area_type_id: current_signed_model.allowed_area_ids).group_by do |f|
      f.date.strftime("%Y-%m-%d")
    end.sort_by do |i,data|
      i
    end.reverse

    @history_date_data.each do |date_data|
      date = date_data.first.to_date
      day_calculation = @restaurant.day_calculations.all.find_by(date: date)
      date_data.push day_calculation
    end

    render "dashboard/history"
  end

  def show_reports
    @body_class = "reports"
    @show_only_current_employee = current_employee
    @show_reports_url_scoped = employees_show_reports_path
    @show_reports_scope = "employees"
    @calculation_exist = true
    @show_totals = ["all", "no employee"].include?(params[:employee_id].downcase) && ["all", "no position"].include?(params[:position_type_id].downcase)

    colors = {}
    @restaurant.area_types.each {|at| colors[at.name] = at.chart_color}
    gon.area_colors = colors

    calculations = Calculation.report_by(@restaurant, params)

    respond_to do |format|
      format.html {
        @positions_scope = ReportsHelper.get_reports(@restaurant, calculations, params)
        render "/dashboard/reports"
      }
      format.xlsx {
        @positions_scope = ReportsHelper.get_excel_report(@restaurant, calculations, params)
        render xlsx: 'reports', template: 'dashboard/reports', filename: "reports.xlsx", disposition: 'inline', xlsx_created_at: 3.days.ago, xlsx_author: "Tipmetric.com"
      }
    end
  end

  def dashboard_post
    redirect_to employees_dashboard_path(params)
  end

  def calculation
    before_calculation
    render "/dashboard/calculation"
  end

  def show_calculation
    get_calculation_data
    render "dashboard/calculation"
  end

  def show_calculation_get
    get_calculation_data
    render "dashboard/calculation"
  end

  def set_info
    @restaurant = current_employee.restaurant

    @total_collected_money_data = @restaurant.total_collected_money_data({employee: current_employee})
    @total_collected_money_data_total = to_2_decimals(@total_collected_money_data.compact.reduce(:+))
    gon.total_collected_money_data = @total_collected_money_data
  end

  def after_sign_in_path_for(resource)
    employees_dashboard_path
  end

  def after_sign_up_path_for(resource)
    employees_dashboard_path
  end
end