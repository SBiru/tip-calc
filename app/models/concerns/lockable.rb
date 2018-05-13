module Lockable
  extend ActiveSupport::Concern

  included do
    validate :restrict_locked, on: [:create, :update]
    before_destroy :restrict_locked
  end

  def restrict_locked
    if is_locked?
      errors.add(:base, "Day is locked.")
      return false
    end
  end

  def is_locked?
    case self.class
    when Calculation
      if day_calculation.present?
        day_calculation.locked?
      else
        dc = restaurant.day_calculations.find_or_create_by(date: date)
        dc.locked?
      end
    when EmployeeDistribution
      if pending_approval? 
        day_calculation = restaurant.day_calculations.find_or_create_by(date: date)
        day_calculation.locked?
      else
        calculation.present? && calculation.is_locked?
      end
    when PercentDistribution
      calculation.present? && calculation.is_locked?
    when TipOut
      sender_calculation.present? && sender_calculation.is_locked?
    end
  end
end
