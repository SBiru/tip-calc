class Employee
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Sequencer
  include Deactivationable
  include DeviseModel

  belongs_to :restaurant
  has_and_belongs_to_many :position_types
  has_many :employee_distributions, dependent: :destroy
  has_and_belongs_to_many :allowed_areas, class_name: "AreaType", inverse_of: :allowed_employees

  field :emp_id, type: String
  field :first_name, default: "First Name"
  field :last_name, default: "Last Name"
  field :registered, type: Boolean, default: false

  validates :emp_id, :first_name, :last_name, :restaurant, :position_types, presence: true
  validates :emp_id, :email, uniqueness: { scope: :restaurant, case_sensitive: false }

  before_validation :set_temporary_password_and_email, on: :create

  def set_temporary_password_and_email
    emp_string = "employee_id_#{ emp_id }_#{ Time.zone.now.to_date.strftime("%Y-%m-%dT%H:%M:%S") }".gsub(" ", "")

    self.email = "#{ emp_string }@tipmetric.com"
    self.password = "#{ emp_string }"
  end

  def available_areas_json
    allowed_areas.map{|f| { name: f.name, id: f.id.to_s } }
  end

  def has_access_to?(id)
    allowed_area_ids.map{|f| f.to_s}.include?(id)
  end

  def is_admin?
    false
  end

  def has_accessed_areas
    allowed_areas.any?
  end

  def integrated_info
    "#{ first_name } #{ last_name } (#{emp_id})"
  end

  def integrated_full_info
    line = "#{ first_name } #{ last_name } (#{emp_id})"
    line += " (deactivated)" if !active
    line
  end

  def related_calculations
    ids = employee_distributions.approved.collect{|f| f.calculation.id }
  end

  def sales
    0
  end

  def tips_collected
    0
  end

  def tips_sales
    0
  end

  def can_be_destroyed?
    employee_distributions.empty?
  end

  def deactivate_with_position(position_type_id)
    response = if employee_distributions.where(position_type_id: position_type_id).empty?
      position = PositionType.find(position_type_id)
      position.employees.delete(self)
      self.position_types.delete(position)
      "depositioned"
    elsif employee_distributions.where(position_type_id: position_type_id).any?
      self.active = false
      self.save
      "deactivated"
    end

    if position_types.empty? && employee_distributions.empty?
      destroy
      response = "destroyed"
    end

    response
  end
end
