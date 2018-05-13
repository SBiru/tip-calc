class ReportsHelper
  class << self
    def options_merged(restaurant, params)
      start_date =  Time.strptime(params[:start], "%m/%d/%Y").to_date
      end_date =  Time.strptime(params[:end], "%m/%d/%Y").to_date

      options = {}

      options.merge!({date: (start_date..end_date)})
      options.merge!({area_type_id: params[:area_type_id]}) unless params[:area_type_id].downcase == "all"
      options.merge!({shift_type_id: params[:shift_type_id]}) unless params[:shift_type_id].downcase == "all"

      return options
    end

    def options_merged_individual(date, area_type_id, shift_type_id)
      options = {}

      options.merge!({date: date}) if date.present?
      options.merge!({area_type_id: area_type_id}) unless area_type_id.downcase == "all"
      options.merge!({shift_type_id: shift_type_id}) unless shift_type_id.downcase == "all"

      return options
    end

    def date_range_stringified(params)
      start_date =  Time.strptime(params[:start], "%m/%d/%Y").strftime("%m_%d_%Y")
      end_date =  Time.strptime(params[:end], "%m/%d/%Y").strftime("%m_%d_%Y")

      "#{ start_date }-#{ end_date }"
    end

    # TOTALS
    # ======

    def total_system(restaurant, date, area_type_id, shift_type_id, employee_id)
      day_area_calcs = if area_type_id.downcase == "all"
        restaurant.day_area_calculations.where(date: date)
      else
        restaurant.day_area_calculations.where(date: date).in(area_type_id: area_type_id)
      end || []

      day_area_calcs.map{|f| f.pos_end_total }.compact.inject(:+) || 0
    end

    def total_tips(restaurant, type, date, area_type_id, shift_type_id, employee_id)
      calcs = if !["all", "no employee"].include?(employee_id.downcase)
        ids = restaurant.employees.find(employee_id).related_calculations
        restaurant.calculations.all.in(id: ids)
      else
        restaurant.calculations.all
      end

      distributions = calcs.where(options_merged_individual(date, area_type_id, shift_type_id)).map{|f| f.employee_distributions}.flatten.compact
      # HERE
      if ["tip-outs-cc", "tip-outs-cash"].include?(type)
        money_type = type == "tip-outs-cc" ? "cc" : "cash"
        {
          given: distributions.map{|f| f.send("tip_outs_given_#{ money_type }") }.inject(:+) || 0,
          received: distributions.map{|f| f.send("tip_outs_received_#{ money_type }") }.inject(:+) || 0
        }
      else
        distributions.map{|f| f.send("#{ type }_tips_distr_final") }.compact.inject(:+) || 0
      end
    end

    # def total_tips_sheets(restaurant, type, date, area_type_id, shift_type_id, employee_id)
    #   calcs = if !["all", "no employee"].include?(employee_id.downcase)
    #     ids = restaurant.employees.find(employee_id).related_calculations
    #     restaurant.calculations.all.in(id: ids)
    #   else
    #     restaurant.calculations.all
    #   end

    #   calcs = calcs.where(options_merged_individual(date, area_type_id, shift_type_id))
    #   # # HERE
    #   if ["tip-outs-cc", "tip-outs-cash"].include?(type)
    #     money_type = type == "tip-outs-cc" ? "cc" : "cash"

    #     {
    #       given: calcs.map{|f| f.send("total_tip_outs_given_#{ money_type }_frontend") }.inject(:+) || 0,
    #       received: calcs.map{|f| f.send("total_tip_outs_received_#{ money_type }_frontend") }.inject(:+) || 0
    #     }
    #   else
    #     calcs.map{|f| f.send("total_tips_distributed_#{ type }_frontend") }.inject(:+) || 0
    #   end
    # end

    # def total_tips_variance(restaurant, type, date, area_type_id, shift_type_id, employee_id)
    #   manual_total = total_tips(restaurant, type, date, area_type_id, shift_type_id, employee_id) || 0
    #   system_total = total_tips_sheets(restaurant, type, date, area_type_id, shift_type_id, employee_id) || 0

    #   if ["tip-outs-cc", "tip-outs-cash"].include?(type)
    #     variance = {
    #       given: (system_total[:given] - manual_total[:given]).abs.try(:round, 2),
    #       received: (system_total[:received] - manual_total[:received]).abs.try(:round, 2)
    #     }
    #     return variance
    #   else
    #     variance = (system_total - manual_total).try(:round, 2)
    #     return variance.abs
    #   end
    # end

    def total_pos_variance(restaurant, date, area_type_id, shift_type_id, employee_id)
      type = "cc"

      manual_total = total_system(restaurant, date, area_type_id, shift_type_id, employee_id) || 0
      system_total = total_tips(restaurant, type, date, area_type_id, shift_type_id, employee_id) || 0

      variance = system_total - manual_total

      return variance.try(:round, 2)
    end

    # HELPERS

    def to_float(number)
      number = number.to_f.round(2)
    end

    # GET DATA

    def get_reports(restaurant, calculations, params)
      # All data for reports pages are being collected in this object
      positions_scope = {}

      # These are all dates, where any calculations present
      positions_scope[:dates] = calculations.collect{|f| f.date }.uniq.sort

      show_employee_stats = params[:position_type_id].downcase != "no position" && params[:employee_id].downcase != "no employee"
      if show_employee_stats
        # If manager wants to see only 1 position data, we show only 1 position data
        if params[:position_type_id].downcase != "all"
          single_position_mode = true
          single_position = restaurant.position_types.find(params[:position_type_id])
        end

        # If manager want to see individual empoyee data, we show only 1 position with only 1 employee data
        if params[:employee_id].downcase != "all"
          single_emp_mode = true
          single_emp_model = restaurant.employees.find(params[:employee_id])
        end

        positions_types = if single_position_mode == true
          # TODO: returning different types, fix it
          [single_position]
        elsif single_emp_mode == true
          single_emp_model.position_types
        else
          calculations.collect{|f| f.employee_distributions }.flatten.compact.group_by{|f| f.position_type }
        end

        # For each position there are statistics
        positions_scope[:position_stat] = {}

        # Employee totals
        positions_types.each do |position, distributions|

          # Base position information
          positions_scope[:position_stat][position.id.to_s] = {
            name: position.name,
            employee_distributions: {},
            day_totals: {},
            position_totals: {}
          }

          employee_distributions = {}

          position_distributions = if single_emp_mode == true
            single_emp_model.employee_distributions.in(calculation_id: calculations.collect(&:id), position_type: position)
          elsif single_position_mode == true
            single_position.employee_distributions.in(calculation_id: calculations.collect(&:id))
          else
            distributions
          end.group_by do |distr|
            distr.employee
          end

          # Data for each employees collected here
          # ======================================
          position_distributions.each do |employee, emp_dist|
            employee_distributions[employee.id.to_s] = {
              empoyee_data: employee,
              distributions: emp_dist,
              employee_totals: {
                cc: ReportsHelper.to_float(emp_dist.map{|f| f.cc_tips_distr_final }.inject(:+)),
                cash: ReportsHelper.to_float(emp_dist.map{|f| f.cash_tips_distr_final }.inject(:+)),
                total: ReportsHelper.to_float(emp_dist.map{|f| f.cc_tips_distr_final + f.cash_tips_distr_final }.inject(:+)),
                tip_outs: {
                  given: {
                    cc: ReportsHelper.to_float(emp_dist.map{|f| f.tip_outs_given_cc }.inject(:+)),
                    cash: ReportsHelper.to_float(emp_dist.map{|f| f.tip_outs_given_cash }.inject(:+))
                  },
                  received: {
                    cc: ReportsHelper.to_float(emp_dist.map{|f| f.tip_outs_received_cc }.inject(:+)),
                    cash: ReportsHelper.to_float(emp_dist.map{|f| f.tip_outs_received_cash }.inject(:+))
                  }
                }
              }
            }

            employee_distributions[employee.id.to_s][:day_distributions] = {}

            positions_scope[:dates].each do |date|
              employee_distributions[employee.id.to_s][:day_distributions][date.to_date] = if emp_dist.select{|f| f.calculation.date == date }.any?
                distributions = emp_dist.select{|f| f.calculation.date == date }

                {
                  cc: ReportsHelper.to_float(distributions.map{|f| f.cc_tips_distr_final }.inject(:+) ),
                  cash: ReportsHelper.to_float(distributions.map{|f| f.cash_tips_distr_final }.inject(:+) ),
                  total: ReportsHelper.to_float(distributions.map{|f| f.cc_tips_distr_final + f.cash_tips_distr_final }.inject(:+) ),
                  tip_outs: {
                    given: {
                      cc: ReportsHelper.to_float(distributions.map{|f| f.tip_outs_given_cc }.inject(:+)),
                      cash: ReportsHelper.to_float(distributions.map{|f| f.tip_outs_given_cash }.inject(:+))
                    },
                    received: {
                      cc: ReportsHelper.to_float(distributions.map{|f| f.tip_outs_received_cc }.inject(:+)),
                      cash: ReportsHelper.to_float(distributions.map{|f| f.tip_outs_received_cash }.inject(:+))
                    }
                  }
                }
              else
                nil
              end
            end
          end
          positions_scope[:position_stat][position.id.to_s][:employee_distributions] = employee_distributions

          # Daily totals
          # ============
          all_days_distributions = position_distributions.collect{|f| f[1]}.flatten.collect{|f| f }.flatten.compact

          positions_scope[:dates].each do |date|
            day_distrs = all_days_distributions.select{|f| f.calculation.date == date }

            info = {}
            info[:cc] = ReportsHelper.to_float(day_distrs.map{|f| f.cc_tips_distr_final }.inject(:+))
            info[:cash] = ReportsHelper.to_float(day_distrs.map{|f| f.cash_tips_distr_final }.inject(:+))
            info[:total] = ReportsHelper.to_float(day_distrs.map{|f| f.cc_tips_distr_final + f.cash_tips_distr_final }.inject(:+))
            info[:tip_outs] = {
              given: {
                cc: ReportsHelper.to_float(day_distrs.map{|f| f.tip_outs_given_cc }.inject(:+)),
                cash: ReportsHelper.to_float(day_distrs.map{|f| f.tip_outs_given_cash }.inject(:+))
              },
              received: {
                cc: ReportsHelper.to_float(day_distrs.map{|f| f.tip_outs_received_cc }.inject(:+)),
                cash: ReportsHelper.to_float(day_distrs.map{|f| f.tip_outs_received_cash }.inject(:+))
              }
            }

            positions_scope[:position_stat][position.id.to_s][:day_totals][date] = info
          end

          #Positions Totals
          # ===============
          related_distrs = position_distributions.collect{|f| f[1]}.flatten

          positions_scope[:position_stat][position.id.to_s][:position_totals] = {
            cc: ReportsHelper.to_float(related_distrs.map{|f| f.cc_tips_distr_final }.inject(:+)),
            cash: ReportsHelper.to_float(related_distrs.map{|f| f.cash_tips_distr_final }.inject(:+)),
            total: ReportsHelper.to_float(related_distrs.map{|f| f.cc_tips_distr_final + f.cash_tips_distr_final }.inject(:+)),
            tip_outs: {
              given: {
                cc: ReportsHelper.to_float(related_distrs.map{|f| f.tip_outs_given_cc }.inject(:+)),
                cash: ReportsHelper.to_float(related_distrs.map{|f| f.tip_outs_given_cash }.inject(:+))
              },
              received: {
                cc: ReportsHelper.to_float(related_distrs.map{|f| f.tip_outs_received_cc }.inject(:+)),
                cash: ReportsHelper.to_float(related_distrs.map{|f| f.tip_outs_received_cash }.inject(:+))
              }
            }
          }
        end
      end

      if params[:show_totals]
        #Totals table
        positions_scope[:totals] = get_totals(restaurant, params[:area_type_id], params[:shift_type_id], params[:employee_id], positions_scope[:dates], calculations)
      end

      return positions_scope
    end
    def get_excel_report(restaurant, calculations, params)
      # All data for reports pages are being collected in this object
      positions_scope = {}

      # These are all dates, where any calculations present
      positions_scope[:dates] = calculations.collect{|f| f.date }.uniq.sort

      show_employee_stats = params[:position_type_id].downcase != "no position" && params[:employee_id].downcase != "no employee"
      if show_employee_stats
        # If manager wants to see only 1 position data, we show only 1 position data
        if params[:position_type_id].downcase != "all"
          single_position_mode = true
          single_position = restaurant.position_types.find(params[:position_type_id])
        end

        # If manager want to see individual empoyee data, we show only 1 position with only 1 employee data
        if params[:employee_id].downcase != "all"
          single_emp_mode = true
          single_emp_model = restaurant.employees.find(params[:employee_id])
        end

        positions_types = if single_position_mode == true
          # TODO: returning different types, fix it
          [single_position]
        elsif single_emp_mode == true
          single_emp_model.position_types
        else
          calculations.collect{|f| f.employee_distributions }.flatten.compact.group_by{|f| f.position_type }
        end

        # For each position there are statistics
        positions_scope[:position_stat] = {}

        # Employee totals
        positions_types.each do |position, distributions|

          # Base position information
          positions_scope[:position_stat][position.id.to_s] = {
            name: position.name,
            employee_distributions: {},
          }

          employee_distributions = {}

          position_distributions = if single_emp_mode == true
            single_emp_model.employee_distributions.in(calculation_id: calculations.collect(&:id), position_type: position)
          elsif single_position_mode == true
            single_position.employee_distributions.in(calculation_id: calculations.collect(&:id))
          else
            distributions
          end.group_by do |distr|
            distr.employee
          end

          # Data for each employees collected here
          # ======================================
          position_distributions.each do |employee, emp_dist|
            employee_distributions[employee.id.to_s] = {
              empoyee_data: employee,
              employee_totals: {
                cc: ReportsHelper.to_float(emp_dist.map{|f| f.cc_tips_distr_final || 0 }.inject(:+)),
                cash: ReportsHelper.to_float(emp_dist.map{|f| f.cash_tips_distr_final || 0 }.inject(:+)),
              }
            }

          end
          positions_scope[:position_stat][position.id.to_s][:employee_distributions] = employee_distributions
        end
      end

      return positions_scope
    end

    def get_daily_excel_report(restaurant, calculations, params)
      # All data for reports pages are being collected in this object
      positions_scope = {}

      # These are all dates, where any calculations present
      positions_scope[:dates] = calculations.collect{|f| f.date }.uniq.sort

      show_employee_stats = params[:position_type_id].downcase != "no position" && params[:employee_id].downcase != "no employee"
      if show_employee_stats
        # If manager wants to see only 1 position data, we show only 1 position data
        if params[:position_type_id].downcase != "all"
          single_position_mode = true
          single_position = restaurant.position_types.find(params[:position_type_id])
        end

        # If manager want to see individual empoyee data, we show only 1 position with only 1 employee data
        if params[:employee_id].downcase != "all"
          single_emp_mode = true
          single_emp_model = restaurant.employees.find(params[:employee_id])
        end

        positions_types = if single_position_mode == true
          # TODO: returning different types, fix it
          [single_position]
        elsif single_emp_mode == true
          single_emp_model.position_types
        else
          calculations.collect{|f| f.employee_distributions }.flatten.compact.group_by{|f| f.position_type }
        end

        # For each position there are statistics
        positions_scope[:position_stat] = {}

        # Employee totals
        positions_types.each do |position, distributions|

          # Base position information
          positions_scope[:position_stat][position.id.to_s] = {
            name: position.name,
            employee_distributions: {},
          }

          employee_distributions = {}

          position_distributions = if single_emp_mode == true
            single_emp_model.employee_distributions.in(calculation_id: calculations.collect(&:id), position_type: position)
          elsif single_position_mode == true
            single_position.employee_distributions.in(calculation_id: calculations.collect(&:id))
          else
            distributions
          end.group_by do |distr|
            distr.employee
          end

          # Data for each employees collected here
          # ======================================
          position_distributions.each do |employee, emp_dist|
            employee_distributions[employee.id.to_s] = {
              empoyee_data: employee,
              employee_totals: {
                cc: ReportsHelper.to_float(emp_dist.map{|f| f.cc_tips_distr_final || 0 }.inject(:+)),
                cash: ReportsHelper.to_float(emp_dist.map{|f| f.cash_tips_distr_final || 0 }.inject(:+)),
                hours: ReportsHelper.to_float(emp_dist.map{|f| f.hours_worked || 0 }.inject(:+)),
              }
            }

            employee_distributions[employee.id.to_s][:daily] = {}

            positions_scope[:dates].each do |date|

              date_distributions = emp_dist.select{|f| f.calculation_date == date }

              employee_distributions[employee.id.to_s][:daily][date] = {
                day_name: date.strftime("%A"),
                cc: ReportsHelper.to_float(date_distributions.map{|f| f.cc_tips_distr_final || 0 }.inject(:+)),
                cash: ReportsHelper.to_float(date_distributions.map{|f| f.cash_tips_distr_final || 0 }.inject(:+)),
                hours: ReportsHelper.to_float(date_distributions.map{|f| f.hours_worked || 0 }.inject(:+))
              }
            end




          end
          positions_scope[:position_stat][position.id.to_s][:employee_distributions] = employee_distributions
        end
      end

      return positions_scope
    end

    def get_totals(restaurant, area_type_id, shift_type_id, employee_id, dates, calculations)
      totals = {}
      uniq_areas = calculations.map{|f| f.area_type }.uniq

      # cc tips
      ["cc", "cash", "global", "tip-outs-cc", "tip-outs-cash"].each do |type|
        totals[type.to_sym] = {}

        # TIPS
        # ====

        totals[type.to_sym]["#{ type }_tips".to_sym] = {
          name: "Total Reports Page (#{ type.gsub('-', ' ') })",
          tr_class: "total-#{ type }-tips",
          by_date: {},
          by_date_and_area: {}
        }
        dates.each do |date|
          totals[type.to_sym]["#{ type }_tips".to_sym][:by_date][date] = total_tips(restaurant, type, date, area_type_id, shift_type_id, employee_id)

          uniq_areas.each do |uniq_area|
            totals[type.to_sym]["#{ type }_tips".to_sym][:by_date_and_area][uniq_area.id.to_s] ||= {}
            totals[type.to_sym]["#{ type }_tips".to_sym][:by_date_and_area][uniq_area.id.to_s][:name] = uniq_area.name
            totals[type.to_sym]["#{ type }_tips".to_sym][:by_date_and_area][uniq_area.id.to_s][:by_date] ||= {}
            totals[type.to_sym]["#{ type }_tips".to_sym][:by_date_and_area][uniq_area.id.to_s][:by_date][date] = total_tips(restaurant, type, date, uniq_area.id.to_s, shift_type_id, employee_id)
          end
        end

        # HERE
        if ["tip-outs-cc", "tip-outs-cash"].include?(type)
          money_type = type == "tip-outs-cc" ? "cc" : "cash"

          totals[type.to_sym]["#{ type }_tips".to_sym][:scope_total] = {
            given: totals[type.to_sym]["#{ type }_tips".to_sym][:by_date].values.map{|f| f[:given] }.compact.inject(:+),
            received: totals[type.to_sym]["#{ type }_tips".to_sym][:by_date].values.map{|f| f[:received] }.compact.inject(:+)
          }

          uniq_areas.each do |uniq_area|
            given_sum = dates.map do |date|
              totals[type.to_sym]["#{ type }_tips".to_sym][:by_date_and_area][uniq_area.id.to_s][:by_date][date][:given]
            end.inject(:+)
            received_sum = dates.map do |date|
              totals[type.to_sym]["#{ type }_tips".to_sym][:by_date_and_area][uniq_area.id.to_s][:by_date][date][:received]
            end.inject(:+)

            sum = {
              given: given_sum,
              received: received_sum
            }

            totals[type.to_sym]["#{ type }_tips".to_sym][:by_area] ||= {}
            totals[type.to_sym]["#{ type }_tips".to_sym][:by_area][uniq_area.id.to_s] = sum
          end
        else
          uniq_areas.each do |uniq_area|
            sum = dates.map do |date|
              totals[type.to_sym]["#{ type }_tips".to_sym][:by_date_and_area][uniq_area.id.to_s][:by_date][date]
            end.inject(:+)

            totals[type.to_sym]["#{ type }_tips".to_sym][:by_area] ||= {}
            totals[type.to_sym]["#{ type }_tips".to_sym][:by_area][uniq_area.id.to_s] = sum
          end

          totals[type.to_sym]["#{ type }_tips".to_sym][:scope_total] = totals[type.to_sym]["#{ type }_tips".to_sym][:by_date].values.inject(:+)
        end

        # TIPS SHEETS
        # ===========

        # NOTE: Turned off for now

        # totals[type.to_sym]["#{ type }_tips_sheets".to_sym] = {
        #   name: "Total Calculation Page (#{ type.gsub('-', ' ') })",
        #   tr_class: "total-#{ type }-tips-sheets",
        #   by_date: {},
        #   by_date_and_area: {}
        # }
        # dates.each do |date|
        #   totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_date][date] = total_tips_sheets(restaurant, type, date, area_type_id, shift_type_id, employee_id)

        #   uniq_areas.each do |uniq_area|
        #     totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_date_and_area][uniq_area.id.to_s] ||= {}
        #     totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_date_and_area][uniq_area.id.to_s][:name] = uniq_area.name
        #     totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_date_and_area][uniq_area.id.to_s][:by_date] ||= {}
        #     totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_date_and_area][uniq_area.id.to_s][:by_date][date] = total_tips_sheets(restaurant, type, date, uniq_area.id.to_s, shift_type_id, employee_id)
        #   end
        # end

        # if ["tip-outs-cc", "tip-outs-cash"].include?(type)
        #   money_type = type == "tip-outs-cc" ? "cc" : "cash"

        #   totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:scope_total] = {
        #     given: totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_date].values.map{|f| f[:given] }.compact.inject(:+),
        #     received: totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_date].values.map{|f| f[:received] }.compact.inject(:+)
        #   }

        #   uniq_areas.each do |uniq_area|
        #     given_sum = dates.map do |date|
        #       totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_date_and_area][uniq_area.id.to_s][:by_date][date][:given]
        #     end.inject(:+)
        #     received_sum = dates.map do |date|
        #       totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_date_and_area][uniq_area.id.to_s][:by_date][date][:received]
        #     end.inject(:+)

        #     sum = {
        #       given: given_sum,
        #       received: received_sum
        #     }

        #     totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_area] ||= {}
        #     totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_area][uniq_area.id.to_s] = sum
        #   end
        # else
        #   uniq_areas.each do |uniq_area|
        #     sum = dates.map do |date|
        #       totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_date_and_area][uniq_area.id.to_s][:by_date][date]
        #     end.inject(:+)

        #     totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_area] ||= {}
        #     totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_area][uniq_area.id.to_s] = sum
        #   end
        #   totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:scope_total] = totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_date].values.inject(:+)
        # end

        # TIPS VARIANCE
        # =============

        # NOTE: Turned off for now

        # totals[type.to_sym]["total_#{ type }_tips_variance".to_sym] = {
        #   name: "Reports/Calculation Page Variance (#{ type.gsub('-', ' ') })",
        #   tr_class: "total-#{ type }-tips-variance",
        #   by_date: {},
        #   by_date_and_area: {}
        # }
        # dates.each do |date|
        #   totals[type.to_sym]["total_#{ type }_tips_variance".to_sym][:by_date][date] = total_tips_variance(restaurant, type, date, area_type_id, shift_type_id, employee_id)

        #   uniq_areas.each do |uniq_area|
        #     totals[type.to_sym]["total_#{ type }_tips_variance".to_sym][:by_date_and_area][uniq_area.id.to_s] ||= {}
        #     totals[type.to_sym]["total_#{ type }_tips_variance".to_sym][:by_date_and_area][uniq_area.id.to_s][:name] = uniq_area.name
        #     totals[type.to_sym]["total_#{ type }_tips_variance".to_sym][:by_date_and_area][uniq_area.id.to_s][:by_date] ||= {}
        #     totals[type.to_sym]["total_#{ type }_tips_variance".to_sym][:by_date_and_area][uniq_area.id.to_s][:by_date][date] = total_tips_variance(restaurant, type, date, uniq_area.id.to_s, shift_type_id, employee_id)
        #   end
        # end

        # if ["tip-outs-cc", "tip-outs-cash"].include?(type)
        #   money_type = type == "tip-outs-cc" ? "cc" : "cash"

        #   totals[type.to_sym]["total_#{ type }_tips_variance".to_sym][:scope_total] = {
        #     given: totals[type.to_sym]["total_#{ type }_tips_variance".to_sym][:by_date].values.map{|f| f[:given] }.compact.inject(:+),
        #     received: totals[type.to_sym]["total_#{ type }_tips_variance".to_sym][:by_date].values.map{|f| f[:received] }.compact.inject(:+)
        #   }

        #   uniq_areas.each do |uniq_area|
        #     given_variance = totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_area][uniq_area.id.to_s][:given] - totals[type.to_sym]["#{ type }_tips".to_sym][:by_area][uniq_area.id.to_s][:given].round(2)
        #     received_variance = totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_area][uniq_area.id.to_s][:received] - totals[type.to_sym]["#{ type }_tips".to_sym][:by_area][uniq_area.id.to_s][:received].round(2)

        #     variance = {
        #       given: given_variance,
        #       received: received_variance
        #     }

        #     totals[type.to_sym]["total_#{ type }_tips_variance".to_sym][:by_area] ||= {}
        #     totals[type.to_sym]["total_#{ type }_tips_variance".to_sym][:by_area][uniq_area.id.to_s] = variance
        #   end
        # else
        #   uniq_areas.each do |uniq_area|
        #     variance = totals[type.to_sym]["#{ type }_tips_sheets".to_sym][:by_area][uniq_area.id.to_s] - totals[type.to_sym]["#{ type }_tips".to_sym][:by_area][uniq_area.id.to_s]

        #     totals[type.to_sym]["total_#{ type }_tips_variance".to_sym][:by_area] ||= {}
        #     totals[type.to_sym]["total_#{ type }_tips_variance".to_sym][:by_area][uniq_area.id.to_s] = variance.round(2)
        #   end
        #   totals[type.to_sym]["total_#{ type }_tips_variance".to_sym][:scope_total] = totals[type.to_sym]["total_#{ type }_tips_variance".to_sym][:by_date].values.inject(:+)
        # end
      end

      # POS END Totals are shown only for situations like:
      # 1) ALL AREAS + ALL SHIFTS
      # 2) 1 AREA + ALL SHIFTS
      if shift_type_id.downcase == "all"
        # total tips
        totals[:cc][:total_system_cc] = {
          name: "Pos End of Day Total (cc)",
          tr_class: "total-pos-tips-variance",
          by_date: {},
          by_date_and_area: {}
        }
        dates.each do |date|
          totals[:cc][:total_system_cc][:by_date][date] = total_system(restaurant, date, area_type_id, shift_type_id, employee_id)

          uniq_areas.each do |uniq_area|
            totals[:cc][:total_system_cc][:by_date_and_area][uniq_area.id.to_s] ||= {}
            totals[:cc][:total_system_cc][:by_date_and_area][uniq_area.id.to_s][:name] = uniq_area.name
            totals[:cc][:total_system_cc][:by_date_and_area][uniq_area.id.to_s][:by_date] ||= {}
            totals[:cc][:total_system_cc][:by_date_and_area][uniq_area.id.to_s][:by_date][date] = total_system(restaurant, date, uniq_area.id.to_s, shift_type_id, employee_id)
          end
        end

        uniq_areas.each do |uniq_area|
          sum = dates.map do |date|
            totals[:cc][:total_system_cc][:by_date_and_area][uniq_area.id.to_s][:by_date][date]
          end.inject(:+)

          totals[:cc][:total_system_cc][:by_area] ||= {}
          totals[:cc][:total_system_cc][:by_area][uniq_area.id.to_s] = sum
        end

        totals[:cc][:total_system_cc][:scope_total] = totals[:cc][:total_system_cc][:by_date].values.inject(:+)

        # total tips
        totals[:cc][:total_system_variance_cc] = {
          name: "Report/Pos End of Day Variance (cc)",
          tr_class: "total-system-variance",
          by_date: {},
          by_date_and_area: {}
        }
        dates.each do |date|
          totals[:cc][:total_system_variance_cc][:by_date][date] = total_pos_variance(restaurant, date, area_type_id, shift_type_id, employee_id)

          uniq_areas.each do |uniq_area|
            totals[:cc][:total_system_variance_cc][:by_date_and_area][uniq_area.id.to_s] ||= {}
            totals[:cc][:total_system_variance_cc][:by_date_and_area][uniq_area.id.to_s][:name] = uniq_area.name
            totals[:cc][:total_system_variance_cc][:by_date_and_area][uniq_area.id.to_s][:by_date] ||= {}
            totals[:cc][:total_system_variance_cc][:by_date_and_area][uniq_area.id.to_s][:by_date][date] = total_pos_variance(restaurant, date, uniq_area.id.to_s, shift_type_id, employee_id)
          end
        end

        uniq_areas.each do |uniq_area|
          sum = dates.map do |date|
            totals[:cc][:total_system_variance_cc][:by_date_and_area][uniq_area.id.to_s][:by_date][date]
          end.inject(:+)

          totals[:cc][:total_system_variance_cc][:by_area] ||= {}
          totals[:cc][:total_system_variance_cc][:by_area][uniq_area.id.to_s] = sum
        end

        totals[:cc][:total_system_variance_cc][:scope_total] = totals[:cc][:total_system_variance_cc][:by_date].values.inject(:+)
      end

      return totals
    end
  end
end
