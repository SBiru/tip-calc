module Deactivationable
  extend ActiveSupport::Concern

  included do
    field :active, type: Boolean, default: true
    scope :active, -> { where(active: true) }
    scope :deactivated, -> { where(active: false) }
  end

  def clear_blanks!
    restaurant.destroy_blanks!
  end

  def activate
    self.active = true
    self.save
  end

  def deactivate
    clear_blanks!
    if can_be_destroyed?
      self.destroy
    else
      self.active = false
      self.save
    end
  end

  def status
    active? ? "active" : "deactivated"
  end
end