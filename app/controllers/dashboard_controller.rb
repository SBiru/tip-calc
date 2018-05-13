class DashboardController < ApplicationController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  layout "admin"

  skip_before_action :verify_authenticity_token
  before_action :authenticate_model!
  before_action :authenticate_admin!, only: [:restaurants, :set_restaurant, :messages, :subscribers]
  before_action :set_info

  def dashboard
    @body_class = "dashboard"
    @dashboard_post_url_scoped = dashboard_post_path
    @show_rating = true

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

    calcs_day = @restaurant.calculations.where(date: day)
    calcs_week = @restaurant.calculations.where(date: monday..day)
    calcs_month = @restaurant.calculations.where(date: first_of_month..day)

    @cc_day = calcs_day.collect{|f| f.total_cc_tips(:unscoped) }.compact.reduce(:+).try(:round, 2) || 0
    @cc_week = calcs_week.collect{|f| f.total_cc_tips(:unscoped) }.compact.reduce(:+).try(:round, 2) || 0

    @cash_day = calcs_day.collect{|f| f.total_cash_tips(:unscoped) }.compact.reduce(:+).try(:round, 2) || 0
    @cash_week = calcs_week.collect{|f| f.total_cash_tips(:unscoped) }.compact.reduce(:+).try(:round, 2) || 0

    @total_day = calcs_day.collect{|f| f.total_cc_tips(:unscoped) + f.total_cash_tips(:unscoped) }.compact.reduce(:+).try(:round, 2) || 0
    @total_week = calcs_week.collect{|f| f.total_cc_tips(:unscoped) + f.total_cash_tips(:unscoped) }.compact.reduce(:+).try(:round, 2) || 0

    @sales_day = calcs_day.collect{|f| f.total_sales(:unscoped) }.compact.reduce(:+).try(:round, 2) || 0
    @sales_week = calcs_week.collect{|f| f.total_sales(:unscoped) }.compact.reduce(:+).try(:round, 2) || 0

    # Data for employees list

    emp_distrs_day = @restaurant.employee_distributions.unscoped.where(calculation_date: day, is_a_source_distribution: true)
    emp_distrs_week = @restaurant.employee_distributions.unscoped.where(calculation_date: monday..day, is_a_source_distribution: true)
    emp_distrs_month = @restaurant.employee_distributions.unscoped.where(calculation_date: first_of_month..day, is_a_source_distribution: true)

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

    render "shared/dashboard"
  end

  def dashboard_post
    redirect_to dashboard_path(params)
  end

  def history
    @body_class = "history"
    @history_date_data = @restaurant.filled_calculations.group_by do |f|
      f.date.strftime("%Y-%m-%d")
    end.sort_by do |i,data|
      i
    end.reverse

    @history_date_data.each do |date_data|
      date = date_data.first.to_date
      day_calculation = @restaurant.day_calculations.all.find_by(date: date)
      date_data.push day_calculation
    end
  end

  def billing
    @body_class = 'billing'
    user = @restaurant.user

    gon.stripe_current_user = user.stripe_user
    gon.current_user_testing_payments = ["hello@tipmetric.com"].include?(user.email)
    gon.stripe_plans = StripeManager::PLANS
    gon.user_charges = Stripe::Charge.list(customer: user.stripe_id)
    gon.restaurant_name = @restaurant.name
    gon.stripe_key = ENV["stripe_pub_key"]

    # Jessica asked to hide test payment and failed charges for Beabourg

    gon.hidden_charges = [
      "ch_1B53HOHaqQskoiyoPAGIxEYX",
      "ch_1B4yiwHaqQskoiyoxlwaeV50",
      "ch_1B4x1LHaqQskoiyotrMnPO0B"
    ]
  end

  def billing_user
    user = @restaurant.user

    render json: {
      stripe_current_user: user.stripe_user,
      stripe_plans: StripeManager::PLANS,
      user_charges: Stripe::Charge.list(customer: user.stripe_id),
      restaurant_name: @restaurant.name,
      stripe_key: ENV["stripe_pub_key"]
    }, status: 200
  end

  def setup
    @body_class = "setup"
  end

  def employee
    @employees = @restaurant.employees
    @body_class = "employee"

    positions = {}
    @restaurant.position_types.each do |position_type|
      positions[position_type.id.to_s] = {
        name: position_type.name,
        id: position_type.id.to_s,
        status: position_type.status.downcase,
        employees: {}
      }

      position_type.employees.each do |employee|
        positions[position_type.id.to_s][:employees][employee.id.to_s] = {
          id: employee.id.to_s,
          status: employee.status,
          emp_data_status: "persisted",
          first_name: employee.first_name,
          last_name: employee.last_name,
          emp_id: employee.emp_id,
          position_type_id: position_type.id.to_s,
          available_areas: employee.allowed_areas.map{|f| { name: f.name, id: f.id.to_s } }
        }
      end
    end
    gon.areas = @restaurant.area_types.map{|f| { name: f.name, id: f.id.to_s } }

    gon.positions = positions
  end

  def calculation
    before_calculation
  end

  def show_calculation
    get_calculation_data
    render "calculation"
  end

  def show_calculation_get
    get_calculation_data
    render "calculation"
  end

  def reports
    @body_class = "reports"
    @show_reports_scope = "users"
    @show_reports_url_scoped = show_reports_path
  end

  def show_reports
    @body_class = "reports"
    @show_reports_scope = "users"
    @show_reports_url_scoped = show_reports_path
    @calculation_exist = true
    @show_totals = ["all", "no employee"].include?(params[:employee_id].downcase) && ["all", "no position"].include?(params[:position_type_id].downcase)
    params[:show_totals] = @show_totals

    colors = {}
    @restaurant.area_types.each {|at| colors[at.name] = at.chart_color}
    gon.area_colors = colors

    date_range_stringified = ReportsHelper.date_range_stringified(params)

    calculations = Calculation.report_by(@restaurant, params)

    respond_to do |format|
      format.html {
        @positions_scope = ReportsHelper.get_reports(@restaurant, calculations, params)
        render "reports"
      }
      format.xlsx {
        if params[:excel_report_type] == "weekly"
          @positions_scope = ReportsHelper.get_excel_report(@restaurant, calculations, params)
          render xlsx: 'reports', template: 'dashboard/reports_weekly', filename: "#{ date_range_stringified } weekly report.xlsx", disposition: 'inline', xlsx_created_at: 3.days.ago, xlsx_author: "Tipmetric.com"
        else
          @positions_scope = ReportsHelper.get_daily_excel_report(@restaurant, calculations, params)
          render xlsx: 'reports', template: 'dashboard/reports_daily', filename: "#{ date_range_stringified } daily report.xlsx", disposition: 'inline', xlsx_created_at: 3.days.ago, xlsx_author: "Tipmetric.com"
        end
      }
    end

  end

  def restaurants

  end

  def day_calculation
    @day_calculation = @restaurant.day_calculations.find(params[:id])
    @changes = @day_calculation.history_tracks
  end

  def set_restaurant
    session[:admin_restaurant_id] = params[:id]
    redirect_to setup_path
  end

  def set_info
    @restaurant = if current_signed_model.is_admin? && session[:admin_restaurant_id] && Restaurant.all.where(id: session[:admin_restaurant_id]).any?
      Restaurant.find(session[:admin_restaurant_id])
    else
      current_signed_model.try(:restaurant)
    end
    @total_collected_money_data = @restaurant.total_collected_money_data
    @total_collected_money_data_total = to_2_decimals(@total_collected_money_data.compact.reduce(:+))
    gon.total_collected_money_data = @total_collected_money_data
  end

  def authenticate_admin!
    redirect_to root_path unless current_user.is_admin?
  end
end
