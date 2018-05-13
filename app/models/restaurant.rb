class Restaurant
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  has_many :area_types, dependent: :destroy
  has_many :shift_types, dependent: :destroy
  has_many :position_types, dependent: :destroy
  has_many :area_shifts, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :calculations, dependent: :destroy
  has_many :employee_distributions, dependent: :destroy
  has_many :day_calculations, dependent: :destroy
  has_many :day_area_calculations, dependent: :destroy

  field :name
  field :permalink
  field :timezone, default: "UTC"
  field :shifted_tip_outs_enabled, default: false
  field :top_employees_is_shown, type: Boolean, default: false

  validates :name, :user, presence: true
  validates :name, uniqueness: { case_sensitive: false }
  before_validation :generate_name
  before_validation :set_permalink

  def generate_name
    unless self.name.present?
      i = 0
      until self.name.present?
        new_name = "Default Name #{ i }"
        self.name = new_name if Restaurant.where(name: new_name).none?
        i = i + 1
      end
    end
  end

  def set_permalink
    self.permalink = name.parameterize
  end

  def to_param
    self.permalink
  end

  def existing_employees
    employees.where(registered: true)
  end

  def unregistered_employees
    employees.where(registered: false)
  end

  def current_time
    Time.zone.now.in_time_zone(timezone)
  end

  def current_date
    current_time.strftime("%m/%d/%y")
  end

  def submit_dates
    if timezone.present?
      [Time.zone.now.in_time_zone(timezone), (Time.zone.now - 1.day).in_time_zone(timezone)]
    else
      [Time.zone.now, Time.zone.now - 1.day]
    end    
  end

  def total_collected_money_data(params=nil)
    date_collections = {}

    today = current_time.to_date
    twoweeksago = current_time.to_date - 13.days
    dates = (twoweeksago..today).map{ |f| f.strftime("%d/%m/%Y") }
    earnings = []

    dates.each do |date|
      if params.try(:[], :employee)
        earning = calculations.all.where(date: date).map{|f| f.employee_distributions.where(employee: params[:employee]) }.flatten.compact.map{|f| (f.cc_tips_distr_final + f.cash_tips_distr_final).try(:round, 2) }.compact.reduce(:+) || 0
      else
        earning = calculations.all.where(date: date).map{|f| f.total_collected_tips(:unscoped) }.compact.reduce(:+) || 0
      end
      earnings << earning
    end

    earnings
  end

  def related_data_inheritance
    area_shifts = self.area_shifts.all.to_a
    area_types_active = self.area_types.active.to_a
    shift_types_active = self.shift_types.active.to_a
    position_types_active = self.position_types.active.to_a
    employees_active = self.employees.active.to_a

    position_employees = {}

    position_types_active.each do |position_type|
      position_type_id = position_type.id
      position_employees[position_type_id] = employees_active.select{|f| f.position_type_ids.include?(position_type_id) }
    end

    # binding.pry

    days = %{ monday tuesday wednesday thursday friday saturday sunday }.split
    data = {}
    days.each do |day|
      day_area_shifts = area_shifts.select{|f| f.days.include?(day)}
      areas = day_area_shifts.collect{|f| f.area_type } & area_types_active

      data[day] = {}
      data[day][:areas] = {}
      areas.each do |area|
        area_id = area.id
        area_name = area.name

        data[day][:areas][area.name] = {
          id: area_id.to_s,
          name: area_name
        }

        shifts = day_area_shifts.select{|a| a.area_type_id == area_id }.collect{|f| f.shift_type } & shift_types_active
        data[day][:areas][area_name][:shifts] = {}

        shifts.each do |shift|
          shift_id = shift.id
          shift_name = shift.name

          data[day][:areas][area_name][:shifts][shift_name] = {
            id: shift_id.to_s,
            name: shift_name
          }
          data[day][:areas][area_name][:shifts][shift_name][:positions] = {}

          position_types = area_shifts.select{|f| f.shift_type_id == shift_id && f.area_type_id == area_id }.first.position_types.active

          position_types.each do |position_type|
            position_type_id = position_type.id
            position_type_name = position_type.name

            data[day][:areas][area_name][:shifts][shift_name][:positions][position_type_name] = {
              id: position_type_id.to_s,
              name: position_type_name,
              employees: position_employees[position_type_id]
            }
          end
        end
      end
    end

    return data
  end

  def related_data_inheritance_old
    area_shifts = self.area_shifts.all

    days = %{ monday tuesday wednesday thursday friday saturday sunday }.split
    data = {}
    days.each do |day|
      areas = area_shifts.select{|f| f.days.include?(day)}.collect{|f| f.area_type }.select{|f| f.active? }
      data[day] = {}
      data[day][:areas] = {}
      areas.each do |area|
        data[day][:areas][area.name] = {
          id: area.id.to_s,
          name: area.name
        }
        shifts = area_shifts.select{|a| a.days.include?(day) && a.area_type == area }.collect{|f| f.shift_type }.select{|f| f.active? }
        data[day][:areas][area.name][:shifts] = {}
        shifts.each do |shift|
          data[day][:areas][area.name][:shifts][shift.name] = {
            id: shift.id.to_s,
            name: shift.name
          }
          data[day][:areas][area.name][:shifts][shift.name][:positions] = {}

          position_types = area_shifts.where(shift_type: shift, area_type: area).first.position_types.active
          position_types.each do |position_type|
            data[day][:areas][area.name][:shifts][shift.name][:positions][position_type.name] = {
              id: position_type.id.to_s,
              name: position_type.name,
              employees: position_type.employees.active
            }
          end
        end
      end
    end

    return data
  end

  def filled_calculations
    calculations.are_filled
  end

  def destroy_blanks!
    calculations.each {|f| f.destroy if f.is_blank? }
  end
end