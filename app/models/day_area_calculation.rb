class DayAreaCalculation
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :calculations
  belongs_to :area_type
  belongs_to :restaurant

  field :date, type: Date
  field :pos_end_total, type: Float

  validates :date, :area_type, presence: true
end