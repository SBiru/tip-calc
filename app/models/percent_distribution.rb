class PercentDistribution
  include Mongoid::Document
  include Mongoid::Timestamps
  include Lockable

  belongs_to :calculation
  belongs_to :position_type
  field :percentage, type: Float, default: 0

  delegate :position_type_name, to: :position_type

  validates :calculation, :position_type, :percentage, presence: true

  def final_percentage
    multiplier = if calculation.percentage_calculation? && calculation.total_tip_outs_given_percentage > 0
      100/(100 - calculation.total_tip_outs_given_percentage)
    else
      1
    end

    percentage/multiplier
  end

end