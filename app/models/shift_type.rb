class ShiftType
  include Mongoid::Document
  include Mongoid::Timestamps
  include NameDowncased
  include Deactivationable

  belongs_to :restaurant
  has_many :area_shifts, dependent: :destroy
  has_many :calculations, dependent: :destroy
  has_many :tip_outs, dependent: :destroy
  has_many :employee_distributions, dependent: :destroy

  field :name

  after_create :create_schedule

  validates :name, :restaurant, presence: true
  validates :name, uniqueness: { case_sensitive: false, scope: :restaurant }

  def create_schedule
    AreaShift.create_for_shift(self)
  end

  def can_be_destroyed?
    calculations.empty?
  end
end
