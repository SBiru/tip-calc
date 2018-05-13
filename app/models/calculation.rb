class Calculation
  include Mongoid::Document
  include Mongoid::Timestamps
  include Lockable

  TYPES = {
    duplicated: "duplicated",
    original: "original"
  }

  DISTRIBUTION_TYPES = {
    percents: "percents",
    points: "points"
  }

  scope :are_filled, -> { where(filled: true) }
  scope :are_blank, -> { where(filled: false) }

  belongs_to :user
  belongs_to :day_calculation
  belongs_to :day_area_calculation
  belongs_to :restaurant

  belongs_to :shift_type
  belongs_to :area_type
  has_many :percent_distributions, dependent: :destroy
  has_many :employee_distributions, dependent: :destroy
  has_many :sender_tip_outs, class_name: "TipOut", inverse_of: :sender_calculation, dependent: :destroy
  has_many :receiver_tip_outs, class_name: "TipOut", inverse_of: :receiver_calculation, dependent: :destroy
  belongs_to :source_position_type, class_name: "PositionType", inverse_of: :sourced_calculations
  has_and_belongs_to_many :source_positions, class_name: "PositionType", inverse_of: :sourced_positioned_calculations

  field :teams_quantity, type: Integer
  field :date, type: Date
  field :pos_total, type: Float
  field :type, default: TYPES[:original]
  field :distribution_type, default: DISTRIBUTION_TYPES[:percents]
  field :filled, type: Boolean, default: false
  field :correct, type: Boolean, default: false

  delegate :position_types, to: :shift_type

  before_create :check_for_duplicates

  after_create :create_percent_distributions, unless: :duplicated?
  after_create :set_db_field_strings
  after_save :calculate_tip_out_summs
  after_save :create_day_calculation
  after_save :create_day_area_calculation
  after_update :update_distributions

  validates :date, :teams_quantity, :user, :restaurant, :shift_type, :area_type, presence: true

  #db optimization fields
  field :area_type_name_string
  field :shift_type_name_string
  field :source_position_type_name_string
  field :used_position_types_string
  field :total_cc_tips_string
  field :total_cash_tips_string

  def check_for_duplicates
    errors.add(:base, "Calculation with the same params already exist") and return false if Calculation.all.where(
      date: date,
      shift_type: shift_type,
      area_type: area_type
    ).select{|f| f.persisted? }.any?
  end

  def params_for_frontend
    {
      source_position_ids: source_position_ids.map{|f| f.to_s },
      date: date.strftime("%m/%d/%Y"),
      area_type_id: area_type_id.to_s,
      shift_type_id: shift_type_id.to_s,
      teams_quantity: teams_quantity
    }
  end

  def set_db_field_strings
    self.used_position_types_string = used_position_types.map{|f| f.name }.join(", ")
    self.area_type_name_string = self.area_type.name
    self.shift_type_name_string = self.shift_type.name
    self.source_position_type_name_string = self.source_positions.map{|f| f.name}.join(", ")
    self.save
  end

  def update_cc_cash_strings
    self.total_cc_tips_string = total_cc_tips.round(2)
    self.total_cash_tips_string = total_cash_tips.round(2)
    self.save
  end

  def create_day_calculation
    unless day_calculation
      day_calc = restaurant.day_calculations.find_or_create_by(date: date)
      self.day_calculation = day_calc
      self.save
    end
  end

  def create_day_area_calculation
    unless day_area_calculation
      day_area_calc = restaurant.day_area_calculations.find_or_create_by(date: date, area_type: area_type)
      self.day_area_calculation = day_area_calc
      self.save
    end
  end

  def related_employees(only_active)
    employees_hash = {}

    scope = only_active ? :active : :all

    used_position_types.each do |position_type|
      employees_hash[position_type.name.downcase] = {
        position_type_id: position_type.id.to_s,
        position_type_name: position_type.name.downcase,
        position_type_is_a_source: source_positions.include?(position_type),
        position_type_is_a_source_integer: source_positions.include?(position_type) ? 1 : 0,
        employees: position_type.employees.send(scope).map do |employee|
          {
            id: employee.id.to_s,
            name: employee.integrated_info,
            emp_id: employee.emp_id.to_s,
            full_info: employee.integrated_full_info
          }
        end
      }
    end

    return employees_hash
  end

  def self.build_by(area_type_id, shift_type_id, date, teams_quantity, source_position_ids, existed_calculation_method, restaurant)
    area = restaurant.area_types.find(area_type_id)
    shift = restaurant.shift_types.find(shift_type_id)
    date = Time.strptime(date, "%m/%d/%Y").to_date
    source_positions = restaurant.position_types.find(source_position_ids).to_a

    calculation = restaurant.calculations.where(
      area_type: area,
      shift_type: shift,
      date: date,
      type: TYPES[:original]
    ).first

    if (calculation.present? && existed_calculation_method == "reset") || (!calculation.present?) || (calculation.present? && calculation.is_blank?)
      calculation.destroy if calculation.present?

      calculation = restaurant.calculations.create(
        area_type: area,
        shift_type: shift,
        date: date,
        teams_quantity: teams_quantity,
        source_positions: source_positions,
        user: restaurant.user
      )
    end

    return calculation
  end

  def create_percent_distributions
    position_types.each do |position_type|
      percent_distributions.create(position_type: position_type, percentage: 0)
    end
  end

  def received_tip_outs
    TipOut.where(
      date: date,
      shift_type: shift_type,
      receiver_id: area_type.id
    )
  end

  def sent_tip_outs
    sender_tip_outs
  end

  def calculate_tip_out_summs
    sent_tip_outs.each {|f| f.calculate_summs }
  end

  def total_cc_tips(scope=nil)
    distributions = scope == :unscoped ? employee_distributions.unscoped : employee_distributions
    distributions.map{|f| f.cc_tips }.compact.reduce(:+) || 0
  end

  def total_sales(scope=nil)
    distributions = scope == :unscoped ? employee_distributions.unscoped : employee_distributions
    distributions.map{|f| f.sales_summ }.compact.reduce(:+) || 0
  end

  def total_cash_tips(scope=nil)
    distributions = scope == :unscoped ? employee_distributions.unscoped : employee_distributions
    distributions.map{|f| f.cash_tips }.compact.reduce(:+) || 0
  end

  def total_collected_tips(scope=nil)
    distributions = scope == :unscoped ? employee_distributions.unscoped : employee_distributions
    distributions.map do |f|
      cc = f.cc_tips || 0
      cash = f.cash_tips || 0
      cc + cash
    end.compact.reduce(:+) || 0
  end

  def update_calculation(params)
    errors.add(:base, 'Day is locked.') and return false if is_locked?

    calculation = self
    restaurant = calculation.restaurant

    #Updating

    if params[:newCalculationParams]
      self.source_position_ids = params[:newCalculationParams][:positions].values.map{|f| f[:position_type_id] }
      self.teams_quantity = params[:newCalculationParams][:team_count].to_i
      self.save
    end

    #POSITIONS

    params["percentage"].each do |position_type_id, percentage|
      distribution = calculation.percent_distributions.find(position_type_id)
      distribution.update(percentage: percentage)
    end

    # POS totals

    self.pos_total = params["posTotals"]["calculationPosTotal"]
    self.distribution_type = params["distribution_type"]
    self.save

    dc = day_area_calculation
    dc.pos_end_total = params["posTotals"]["dayPosTotal"]
    dc.save

    #EMPLOYEE DISTRIBUTIONS
    # we save only cc and cash in numbers, because distribution of tip outs will be made by another script

    new_distributions ||= []

    params["positionsMoney"].each do |position_name, position_data|
      position_data["teams"].each do |team_no, team_data|
        if team_data["employees"]
        team_data["employees"].each do |employee_id, emp_data|
          if emp_data["distributionStatus"] == "persisted"
            distribution = calculation.employee_distributions.find(emp_data["distributionId"])
          else
            employee = restaurant.employees.find(employee_id)
            position = restaurant.position_types.find_by(name: position_name)
            distribution_exists = calculation.employee_distributions.where(employee: employee, position_type: position).any?

            if distribution_exists
              distribution = calculation.employee_distributions.where(
                employee: employee,
                position_type: position
              ).first
            else
              distribution = calculation.employee_distributions.create(
                employee: employee,
                position_type: position
              )
              new_distributions << distribution
            end
          end

          distribution.update(
            hours_worked: emp_data["hoursWorkedInHours"],
            team_number: team_no,

            # distributed
            cc_tips_distr_frontend: emp_data["totalMoneyOut"]["cc"].try(:to_f).try(:round, 2),
            cash_tips_distr_frontend: emp_data["totalMoneyOut"]["cash"].try(:to_f).try(:round, 2),

            #tip outs
            tip_outs_given_cc_frontend: emp_data["totalTipOutsGiven"]["cc"].try(:to_f).try(:round, 2),
            tip_outs_given_cash_frontend: emp_data["totalTipOutsGiven"]["cash"].try(:to_f).try(:round, 2),
            tip_outs_received_cc_frontend: emp_data["totalTipOutsReceived"]["cc"].try(:to_f).try(:round, 2),
            tip_outs_received_cash_frontend: emp_data["totalTipOutsReceived"]["cash"].try(:to_f).try(:round, 2),

            #final
            cc_tips_distr_final_frontend: emp_data["finalMoneyToDistribute"]["cc"].try(:to_f).try(:round, 2),
            cash_tips_distr_final_frontend: emp_data["finalMoneyToDistribute"]["cash"].try(:to_f).try(:round, 2),
          )

          distribution.update(
            cash_tips: emp_data["totalMoneyIn"]["cash"],
            cc_tips: emp_data["totalMoneyIn"]["cc"],
            sales_summ: emp_data["salesSumm"]
          ) if position_data["positionTypeIsASource"] == 'true'
        end
        end
      end if position_data.try(:[], "teams")
    end

    if params["tips"].present? && params["tips"]["given"].present?
      params["tips"]["given"].each do |name, data|
        if data['status'] == 'persisted' && data['id'].present?
          tip_out = calculation.sender_tip_outs.find(data['id'])
          tip_out.receiver_id = data["area_type_id"]
          tip_out.shift_type_id = data["shift_type_id"] || calculation.shift_type_id
        else
          tip_out = calculation.sender_tip_outs.build(
            sender_calculation_id: calculation.id,
            receiver_id: data["area_type_id"],
            sender_id: calculation.area_type.id,
            date: calculation.date,
            shift_type_id: data["shift_type_id"] || calculation.shift_type_id
          )
        end

        tip_out.percentage = data["percentage"]
        tip_out.save
        tip_out.calculate_summs

        if tip_out.changes['receiver_id'] || tip_out.changes['shift_type_id']
          previous_calculation_area = tip_out.changes['receiver_id'] ? tip_out.changes['receiver_id'][0] : tip_out.receiver_id
          previous_calculation_shift = tip_out.changes['shift_type_id'] ? tip_out.changes['shift_type_id'][0] : tip_out.shift_type_id
          tip_out.recalculate_previous_calculation(previous_calculation_area, previous_calculation_shift)
        end
      end
    end

    tip_outs = self.sender_tip_outs.map do |t|
      {
        id: t.id.to_s,
        area_type_id: t.receiver_id.to_s,
        shift_type_id: t.shift_type_id.to_s
      }
    end

    recalculate
    return {
      new_distributions: new_distributions,
      tip_outs: tip_outs,
      calculation_params: params_for_frontend
    }
  end

  def total_tip_outs_given_percentage
    sent_tip_outs.map{|f| f.percentage }.compact.reduce(:+) || 0
  end

  def total_tip_outs_given_cc
    sent_tip_outs.map{|f| f.cc_summ }.compact.reduce(:+) || 0
  end

  def total_tip_outs_given_cash
    sent_tip_outs.map{|f| f.cash_summ }.compact.reduce(:+) || 0
  end

  def total_tip_outs_given_global
    sent_tip_outs.map{|f| (f.cc_summ || 0) + (f.cash_summ || 0) }.compact.reduce(:+) || 0
  end

  # Totals from frontend
  # =====================

  # Given

  def total_tip_outs_given_cc_frontend
    employee_distributions.map{|f| f.tip_outs_given_cc_frontend }.compact.reduce(:+) || 0
  end

  def total_tip_outs_given_cash_frontend
    employee_distributions.map{|f| f.tip_outs_given_cash_frontend }.compact.reduce(:+) || 0
  end

  # Received

  def total_tip_outs_received_cc_frontend
    employee_distributions.map{|f| f.tip_outs_received_cc_frontend }.compact.reduce(:+) || 0
  end

  def total_tip_outs_received_cash_frontend
    employee_distributions.map{|f| f.tip_outs_received_cash_frontend }.compact.reduce(:+) || 0
  end

  # Final

  def total_tips_distributed_cc_frontend
    employee_distributions.map{|f| f.cc_tips_distr_final_frontend }.compact.reduce(:+) || 0
  end

  def total_tips_distributed_cash_frontend
    employee_distributions.map{|f| f.cash_tips_distr_final_frontend }.compact.reduce(:+) || 0
  end

  # Global

  def total_tips_distributed_global_frontend
    employee_distributions.map{|f| (f.cc_tips_distr_final_frontend || 0) + (f.cash_tips_distr_final_frontend || 0) }.compact.reduce(:+) || 0
  end

  #=========================

  def total_tip_outs_received_cc
    received_tip_outs.map{|f| f.cc_summ }.compact.reduce(:+) || 0
  end

  def total_tip_outs_received_cash
    received_tip_outs.map{|f| f.cash_summ }.compact.reduce(:+) || 0
  end

  def total_tip_outs_received_global
    received_tip_outs.map{|f| (f.cc_summ || 0) + (f.cash_summ || 0) }.compact.reduce(:+) || 0
  end

  def total_tips_distributed_cc
    employee_distributions.map{|f| f.cc_tips_distr_final }.compact.reduce(:+) || 0
  end

  def total_tips_distributed_cash
    employee_distributions.map{|f| f.cash_tips_distr_final }.compact.reduce(:+) || 0
  end

  def total_tips_distributed_global
    total_tips_distributed_cc + total_tips_distributed_cash
  end

  def recalculate_tipouts
    given_cc = total_tip_outs_given_cc
    given_cash = total_tip_outs_given_cash
    received_cc = total_tip_outs_received_cc
    received_cash = total_tip_outs_received_cash
    total_collected_cc = total_cc_tips
    total_collected_cash = total_cash_tips

    self.employee_distributions.each do |d|
      d.tip_outs_given_cc = ( d.cc_tips_distr * given_cc / total_collected_cc ) || 0
      d.tip_outs_given_cc = d.tip_outs_given_cc.to_f.nan? ? 0 : d.tip_outs_given_cc

      d.tip_outs_given_cash = ( d.cash_tips_distr * given_cash / total_collected_cash ) || 0
      d.tip_outs_given_cash = d.tip_outs_given_cash.to_f.nan? ? 0 : d.tip_outs_given_cash

      d.tip_outs_received_cc = ( received_cc * d.emp_percentage/100 ) || 0
      d.tip_outs_received_cc = d.tip_outs_received_cc.to_f.nan? ? 0 : d.tip_outs_received_cc

      d.tip_outs_received_cash = ( received_cash * d.emp_percentage/100 ) || 0
      d.tip_outs_received_cash = d.tip_outs_received_cash.to_f.nan? ? 0 : d.tip_outs_received_cash

      d.cc_tips_distr_final = ( d.cc_tips_distr - d.tip_outs_given_cc + d.tip_outs_received_cc ) || 0
      d.cc_tips_distr_final = d.cc_tips_distr_final.to_f.nan? ? 0 : d.cc_tips_distr_final

      d.cash_tips_distr_final = ( d.cash_tips_distr - d.tip_outs_given_cash + d.tip_outs_received_cash ) || 0
      d.cash_tips_distr_final = d.cash_tips_distr_final.to_f.nan? ? 0 : d.cash_tips_distr_final

      d.save
    end
  end

  def percentage_calculation?
    distribution_type == "percents"
  end

  def points_calculation?
    distribution_type == "points"
  end

  def recalculate
    reload
    income_types = [:cc_tips, :cash_tips]

    total_money_collected = {}
    total_money_to_distribute = {}

    income_types.each do |income_type|
      total_money_collected[income_type] = self.employee_distributions.map{ |f| f[income_type] }.compact.inject(:+) || 0
      total_money_to_distribute[income_type] = total_money_collected[income_type]
    end

    position_names = self.employee_distributions.collect{|f| f.position_type.name}.uniq

    scope = {}

    calculate_tip_out_summs

    if percentage_calculation?
    position_names.each do |position_name|
      
      position = self.used_position_types.find_by(name: position_name)
      is_a_source = source_positions.include?(position)

      scope[position_name] = {
        is_a_source: is_a_source,
        teams: {},
        collected_by_position: {}
      }
      team_numbers = self.employee_distributions.select do |distr|
        distr.position_type.name == position_name
      end.collect do |distr|
        distr.team_number
      end.uniq.compact

      scope[position_name][:teams_count] = team_numbers.length

      team_numbers.each do |team_number|
        scope[position_name][:teams][team_number] = {}
        scope[position_name][:teams][team_number][:employee_distributions] = self.employee_distributions.select do |distr|
          distr.position_type.name == position_name && distr.team_number == team_number
        end

        position_type = self.used_position_types.find_by(name: position_name)
        position_percentage = self.percent_distributions.find_by(position_type: position_type).percentage
        position_distributions = self.employee_distributions.select do |distr|
          distr.position_type.name == position_name
        end

        if scope[position_name][:is_a_source]
          team_collected_money = {}
          scope[position_name][:teams][team_number][:total_money_to_distribute] = {}

          income_types.each do |income_type|
            team_collected_money[income_type] = scope[position_name][:teams][team_number][:employee_distributions].collect{ |f| f[income_type] }.inject(:+)
            scope[position_name][:collected_by_position][income_type] = position_distributions.collect{ |f| f[income_type] }.inject(:+)

            team_part = if scope[position_name][:teams_count] == 1
              1
            else
              team_collected_money[income_type]/scope[position_name][:collected_by_position][income_type]
            end

            scope[position_name][:teams][team_number][:total_money_to_distribute][income_type] = total_money_collected[income_type]*position_percentage*team_part/100

            total_hours = scope[position_name][:teams][team_number][:employee_distributions].collect{ |f| f.hours_worked }.inject(:+)
            hour_price = scope[position_name][:teams][team_number][:total_money_to_distribute][income_type]/total_hours
            scope[position_name][:teams][team_number][:employee_distributions].each do |emp_distr|
              emp_distr["#{income_type}_distr".to_sym] = hour_price * emp_distr.hours_worked || 0
              emp_distr["#{income_type}_distr".to_sym] = 0 if emp_distr["#{income_type}_distr".to_sym].to_f.nan?
              emp_distr.team_distribution_percentage = (emp_distr.hours_worked/total_hours) || 0
              emp_distr.team_distribution_percentage = 0 if emp_distr.team_distribution_percentage.to_f.nan?
              emp_distr.save
            end
          end
        else
          scope[position_name][:total_money_to_distribute] = {}

          income_types.each do |income_type|
            scope[position_name][:total_money_to_distribute][income_type] = total_money_collected[income_type]*position_percentage/100
            total_hours = scope[position_name][:teams][team_number][:employee_distributions].collect{ |f| f.hours_worked }.inject(:+)
            hour_price = scope[position_name][:total_money_to_distribute][income_type]/total_hours
            scope[position_name][:teams][team_number][:employee_distributions].each do |emp_distr|
              emp_distr["#{income_type}_distr".to_sym] = hour_price * emp_distr.hours_worked || 0
              emp_distr["#{income_type}_distr".to_sym] = 0 if emp_distr["#{income_type}_distr".to_sym].to_f.nan?
              emp_distr.team_distribution_percentage = (emp_distr.hours_worked/total_hours) || 0
              emp_distr.team_distribution_percentage = 0 if emp_distr.team_distribution_percentage.to_f.nan?
              emp_distr.save
            end
          end
        end
      end
    end
    else # => points distribution
      totalCalculationPoints = get_total_calculation_points
      totalCalculationHours = get_total_calculation_hours

      totalCalculationPoints = totalCalculationPoints == 0 ? 1 : totalCalculationPoints

      totalPointPrice = {
        cc_tips: total_money_collected[:cc_tips]/totalCalculationPoints,
        cash_tips: total_money_collected[:cash_tips]/totalCalculationPoints
      }

      position_names.each do |position_name|
        position = self.used_position_types.find_by(name: position_name)
        is_a_source = source_positions.include?(position)

        scope[position_name] = {
          is_a_source: is_a_source,
          teams: {}
        }
        team_numbers = self.employee_distributions.select do |distr|
          distr.position_type.name == position_name
        end.collect do |distr|
          distr.team_number
        end.uniq.compact

        scope[position_name][:teams_count] = team_numbers.length

        team_numbers.each do |team_number|
          scope[position_name][:teams][team_number] = {}
          scope[position_name][:teams][team_number][:employee_distributions] = self.employee_distributions.select do |distr|
            distr.position_type.name == position_name && distr.team_number == team_number
          end

          position_type = self.used_position_types.find_by(name: position_name)
          position_percentage = self.percent_distributions.find_by(position_type: position_type).percentage

          scope[position_name][:total_money_to_distribute] = {}

          income_types.each do |income_type|
            scope[position_name][:teams][team_number][:employee_distributions].each do |emp_distr|
              emp_distr["#{income_type}_distr".to_sym] = totalPointPrice[income_type] * emp_distr.hours_worked * position_percentage || 0
              emp_distr["#{income_type}_distr".to_sym] = 0 if emp_distr["#{income_type}_distr".to_sym].to_f.nan?
              emp_distr.employee_points_part = (position_percentage*emp_distr.hours_worked)/totalCalculationPoints || 0
              emp_distr.employee_points_part = 0 if emp_distr.employee_points_part.to_f.nan?
              emp_distr.save
            end
          end
        end
      end
    end

    recalculate_tipouts
    update_permanent_attributes
  end

  def update_permanent_attributes
    update_cc_cash_strings
    set_filled_attribute
    set_correct_attribute
  end

  def get_total_calculation_points
    position_names = self.employee_distributions.collect{|f| f.position_type.name}.uniq

    position_names.map do |position_name|
      position_type = self.used_position_types.find_by(name: position_name)
      position_points_value = self.percent_distributions.find_by(position_type: position_type).percentage

      totalPositionHours = self.employee_distributions.select do |distr|
        distr.position_type.name == position_name
      end.collect do |f|
        f.hours_worked
      end.inject(:+)

      totalPositionPoints = totalPositionHours * position_points_value

      totalPositionPoints
    end.inject(:+) || 0
  end

  def get_total_calculation_hours
    self.employee_distributions.collect do |distr|
      distr.hours_worked
    end.uniq.compact.inject(:+)
  end

  def position_types
    ids = restaurant.area_shifts.where(area_type_id: area_type_id, shift_type_id: shift_type_id).map do |f|
      f.position_type_ids
    end.flatten.compact

    restaurant.position_types.all.in(id: ids).active
  end

  def used_position_types
    ids = percent_distributions.collect{|f| f.position_type.id.to_s }.flatten.compact
    restaurant.position_types.all.in(id: ids)
  end

  def is_blank?
    employee_distributions.none? &&
    total_percent_distributions == 0 &&
    (pos_total == 0 || pos_total.nil?) &&
    sender_tip_outs.none? &&
    receiver_tip_outs.none? &&
    pending_distributions.none?
  end

  def set_filled_attribute
    self.filled = !is_blank?
    save
  end

  def is_calculation_correct?
    # employee_distributions.any? &&
    # total_percent_distributions_correct? &&
    # (total_cc_tips.round(2) + total_cash_tips.round(2)) > 0 &&
    t1 = total_collected_tips + total_tip_outs_difference
    t2 = total_tips_distributed_global
    variance_pass = (t1 - t2).abs <= 0.01

    variance_pass && pending_distributions.none?
  end

  def total_percent_distributions_correct?
    percentage_calculation? ? total_percent_distributions == 100 : total_percent_distributions > 0
  end

  def total_percent_distributions
    percent_distributions.map(&:percentage).inject(&:+).try(:round, 2) || 0
  end

  def total_tip_outs_difference
    (total_tip_outs_received_global - total_tip_outs_given_global)
  end

  def set_correct_attribute
    self.correct = is_calculation_correct?
    save
  end

  def pending_distributions
    EmployeeDistribution.pending.where(
      area_type: area_type,
      shift_type: shift_type,
      date: date
    )
  end

  def duplicated?
    type == TYPES[:duplicated]
  end

  def duplicate(position_ids=nil)
    source_positions = restaurant.position_types.find(position_ids)

    duplicated_calculation = restaurant.calculations.create(
      shift_type: shift_type,
      area_type: area_type,
      date: date,
      user: user,
      day_calculation: day_calculation,
      day_area_calculation: day_area_calculation,
      teams_quantity: teams_quantity,
      type: TYPES[:duplicated],
      source_positions: source_positions
    )

    percent_distributions.each do |f|
      duplicated_calculation.percent_distributions.create(
        position_type: f.position_type,
        percentage: f.percentage
      )
    end

    source_positions.each do |f|
      unless duplicated_calculation.used_position_types.include?(f)
        duplicated_calculation.percent_distributions.create(
          position_type: f,
          percentage: 0
        )
      end
    end

    return duplicated_calculation
  end

  def update_distributions
    if changes['teams_quantity'] &&
      changes['teams_quantity'][1] &&
      changes['teams_quantity'][0] &&
      changes['teams_quantity'][1] < changes['teams_quantity'][0]

      # Clear removed team inputs
      new_teams = (0..teams_quantity).map{|f| f }
      employee_distributions.each{|f| f.destroy if !new_teams.include?(f.team_number) }
    end

    if changes['source_position_ids'] &&
      changes['source_position_ids'][0] &&
      changes['source_position_ids'][1]

      #remove inputs from non source positions
      initial_positions = changes['source_position_ids'][0]
      final_positions = changes['source_position_ids'][1]
      removal_positions = initial_positions - final_positions
      positions_were_removed = removal_positions.any?

      if positions_were_removed
        employee_distributions.in(position_type_id: removal_positions).each {|f| f.destroy }
      end
    end
  end

  def self.report_by(restaurant, params)
    options = ReportsHelper.options_merged(restaurant, params)

    calculations = if !["all", "no employee"].include?(params[:employee_id].downcase)
      ids = restaurant.employees.find(params[:employee_id]).related_calculations
      restaurant.calculations.in(id: ids)
    else
      restaurant.calculations
    end

    return calculations.where(options)
  end

  # Methods for copying percent distribution percents from another calculation with same Day + Area + Shift

  def percent_variations
    area_shift_calculations = restaurant.calculations.where(area_type_id: area_type_id, shift_type_id: shift_type_id)
    day = date.wday
    same_day_calculations = area_shift_calculations.select{|f| f.date.wday == day }

    json = []
    same_day_calculations.each do |c|
      next if c.id == self.id

      h = {}
      h[c.id] = c.percent_distributions.map do |pd|
        {
          position_type_id: pd.position_type_id,
          position_type_name: pd.position_type.name,
          percentage: pd.final_percentage
        }
      end

      json.push(h)
    end

    unique_json = json.uniq {|k,v| k.values}
    unique_json    
  end
end