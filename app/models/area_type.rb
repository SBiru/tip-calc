class AreaType
  include Mongoid::Document
  include Mongoid::Timestamps
  include NameDowncased
  include Deactivationable

  COLORS = [
    "#004080",
    "#FF6666",
    "#00FF80",
    "#FF8000",
    "#00FFFF",
    "#FFCC66",
    "#0080FF",
    "#808000",
    "#0000FF",
    "#8000FF",
    "#408000",
    "#FF00FF",
    "#808000",
    "#400080",
    "#008080",
    "#FF0080",
    "#66CCFF",
    "#800080",
    "#6666FF",
    "#FF6FCF",
    "#804000",
  ]

  belongs_to :restaurant
  has_many :area_shifts, dependent: :destroy
  has_many :calculations, dependent: :destroy
  has_many :day_area_calculations, dependent: :destroy

  has_many :sender_tip_outs, class_name: "TipOut", inverse_of: :sender, dependent: :destroy
  has_many :receiver_tip_outs, class_name: "TipOut", inverse_of: :receiver, dependent: :destroy
  has_and_belongs_to_many :allowed_employees, class_name: "Employee", inverse_of: :allowed_areas

  field :name
  field :chart_color

  after_create :create_schedule
  after_create :set_color

  validates :name, :restaurant, presence: true
  validates :name, uniqueness: { case_sensitive: false, scope: :restaurant }

  def create_schedule
    AreaShift.create_for_area(self)
  end

  def can_be_destroyed?
    calculations.empty?
  end

  def set_color
    i = restaurant.area_types.order(created_at: :asc).to_a.index(self)
    self.chart_color = COLORS[i]
    self.save
  end
end
