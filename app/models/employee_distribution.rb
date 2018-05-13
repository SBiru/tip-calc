class EmployeeDistribution
  include Mongoid::Document
  include Mongoid::Timestamps
  include Lockable

  belongs_to :restaurant
  belongs_to :calculation
  belongs_to :employee
  belongs_to :position_type
  belongs_to :shift_type
  belongs_to :area_type

  field :status, default: "approved"
  field :date, type: Date
  field :calculation_date, type: Date
  field :is_a_source_distribution, type: Boolean, default: nil

  field :hours_worked, type: Float, default: 0
  field :minutes_worked, type: Float, default: 0
  field :team_distribution_percentage, type: Float, default: 0
  field :employee_points_part, type: Float, default: 0
  field :team_number, type: Integer

  # How much money collected this user
  field :cc_tips, type: Float, default: 0
  field :cash_tips, type: Float, default: 0

  # How much sales did he make
  field :sales_summ, type: Float, default: 0

  # Money distributed to the user (not incuding tip outs)
  field :cc_tips_distr, type: Float, default: 0
  field :cash_tips_distr, type: Float, default: 0

  # Tip outs received and given
  field :tip_outs_given_cc, type: Float, default: 0
  field :tip_outs_given_cash, type: Float, default: 0
  field :tip_outs_received_cc, type: Float, default: 0
  field :tip_outs_received_cash, type: Float, default: 0

  # Money distributed to the user (incuding tip outs given and received)
  field :cc_tips_distr_final, type: Float, default: 0
  field :cash_tips_distr_final, type: Float, default: 0

  # Same numbers, but calculated using frontend JS logic
  field :cc_tips_distr_frontend, type: Float, default: 0
  field :cash_tips_distr_frontend, type: Float, default: 0
  field :tip_outs_given_cc_frontend, type: Float, default: 0
  field :tip_outs_given_cash_frontend, type: Float, default: 0
  field :tip_outs_received_cc_frontend, type: Float, default: 0
  field :tip_outs_received_cash_frontend, type: Float, default: 0
  field :cc_tips_distr_final_frontend, type: Float, default: 0
  field :cash_tips_distr_final_frontend, type: Float, default: 0

  validates :employee, :position_type, presence: true
  validates :calculation, presence: true, unless: :pending_approval?

  before_create :set_date
  before_save :set_calculation_date, if: "calculation_date.nil? && calculation.present?"
  before_save :set_is_a_source_distribution, if: "is_a_source_distribution.nil? && calculation.present?"
  before_save :set_restaurant, if: "restaurant.nil? && calculation.present?"
  before_save :create_missing_calculations
  before_save :data_duplication
  after_create :update_calculations_pending_for, if: :pending_approval?
  after_destroy :update_calculations_pending_for, if: :pending_approval?

  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }

  default_scope -> { approved }

  def create_missing_calculations
    if calculation.nil? and pending_approval? and restaurant?
      calculation = restaurant.calculations.where(
        date: date,
        user: restaurant.user,
        area_type: area_type,
        shift_type: shift_type,
      ).first

      calculation = restaurant.calculations.create(
        date: date,
        user: restaurant.user,
        area_type: area_type,
        shift_type: shift_type,
        teams_quantity: 1,
        source_positions: [position_type],
      ) if calculation.nil?

      self.calculation = calculation
    end
  end

  def total_collected_tips
    (cc_tips || 0) + (cash_tips || 0) 
  end

  def set_restaurant
    self.restaurant = calculation.restaurant
    true
  end

  def set_is_a_source_distribution
    self.is_a_source_distribution = self.calculation.source_positions.include? position_type
    true
  end

  def set_calculation_date
    self.calculation_date = calculation.date
    true
  end

  def global_tips_distr_final
    cc_tips_distr_final + cash_tips_distr_final
  end

  def set_date
    self.date = restaurant.current_time.to_date unless date
  end

  def remove_inputs
    self.cc_tips = 0
    self.cash_tips = 0
    self.save
  end

  def emp_percentage
    if calculation.percentage_calculation?
      position_percentage = self.calculation.percent_distributions.find_by(position_type: position_type).percentage
      teams_count = self.calculation.source_positions.include?(position_type) ? self.calculation.teams_quantity : 1
      emp_percentage = (team_distribution_percentage * position_percentage) / teams_count || 0
    else
      employee_points_part*100 || 0
    end
  end

  def pending_approval?
    status == "pending"
  end

  def approve!(calculation=nil)
    self.calculation = calculation
    self.status = "approved"
    if self.save
      calculation.recalculate
      true
    else
      false
    end
  end

  def decline!(calculation=nil)
    self.destroy
  end

  def data_duplication
    if status_change == ["pending", "approved"] &&
      calculation.employee_distributions.where(position_type_id: position_type_id, employee_id: employee_id).select{|f| f != self }.any?

      errors.add(:base, "There already exists a record for #{ employee.integrated_info }, #{ date.to_date }, #{ area_type.name.titleize }, #{ shift_type.name.titleize }. Please see manager for more information.")
      return false
    end
  end

  def update_calculations_pending_for
    calcs = restaurant.calculations.where(
      area_type: area_type,
      shift_type: shift_type,
      date: date
    )

    calcs.each do |f|
      f.set_filled_attribute
      f.set_correct_attribute
    end
  end
end
