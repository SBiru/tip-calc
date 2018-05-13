class AreaShift
  include Mongoid::Document
  include Mongoid::Timestamps

  DAYS = [
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
    "sunday"
  ]

  belongs_to :restaurant
  belongs_to :area_type
  belongs_to :shift_type
  has_and_belongs_to_many :position_types
  has_many :employee_distributions

  field :days, type: Array, default: []

  validates :restaurant, :area_type, :shift_type, presence: true

  def toggle_day(day, checked)
    if checked == "true"
      add_day(day)
    else
      remove_day(day)
    end
  end

  def add_day(day)
    self.days << day.downcase
    self.days.uniq!
    self.save
  end

  def remove_day(day)
    self.days.delete(day)
    self.save
  end

  def self.checked?(area_type_id, shift_type_id, day)
    AreaShift.where(shift_type_id: shift_type_id, area_type_id: area_type_id).first.days.include?(day)
  end

  def self.create_for_shift(shift_type)
    AreaType.each do |area_type|
      AreaShift.create(shift_type: shift_type, area_type: area_type, restaurant: shift_type.restaurant)
    end
  end

  def self.create_for_area(area_type)
    ShiftType.each do |shift_type|
      AreaShift.create(shift_type: shift_type, area_type: area_type, restaurant: shift_type.restaurant)
    end
  end

  def self.destroy_for_shift(shift_type)
    AreaType.each do |area_type|
      AreaShift.where(shift_type: shift_type, area_type: area_type).first.destroy
    end
  end

  def self.destroy_for_area(area_type)
    ShiftType.each do |shift_type|
      AreaShift.where(shift_type: shift_type, area_type: area_type).first.destroy
    end
  end
end
