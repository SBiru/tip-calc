class PositionType
  include Mongoid::Document
  include Mongoid::Timestamps
  include NameDowncased
  include Deactivationable

  belongs_to :restaurant
  has_and_belongs_to_many :employees
  has_many :percent_distributions, dependent: :destroy
  has_many :employee_distributions, dependent: :destroy
  has_and_belongs_to_many :area_shifts
  has_many :sourced_calculations, class_name: "Calculation", inverse_of: :source_position_type
  has_and_belongs_to_many :sourced_positioned_calculations, class_name: "Calculation", inverse_of: :source_positions

  default_scope -> { order(created_at: :asc) }

  field :name
  field :is_a_source, type: Boolean, default: false # TODO remove this param

  validates :restaurant, :name, presence: true
  validates :name, uniqueness: { case_sensitive: false, scope: :restaurant }

  def works_on?(area_type, shift_type)
    area_shifts.where(area_type: area_type, shift_type: shift_type).any?
  end

  def can_be_destroyed?
    sourced_positioned_calculations.each{|f| f.destroy if f.is_blank? }

    employees.empty? &&
    employee_distributions.empty? &&
    percent_distributions.collect(&:percentage).inject(:+).blank? &&
    sourced_positioned_calculations.empty?
  end

  def deactivate
    if can_be_destroyed?
      percent_distributions.each do |f|
        calculation = f.calculation
        f.destroy
        calculation.reload
        calculation.used_position_types_string = calculation.used_position_types.map{|f| f.name }.join(", ")
        calculation.save
      end
      self.destroy
    else
      self.active = false
      self.save
    end
  end
end
