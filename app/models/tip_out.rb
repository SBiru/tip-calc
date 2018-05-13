class TipOut
  include Mongoid::Document
  include Mongoid::Timestamps
  include Lockable

  belongs_to :sender_calculation, class_name: "Calculation", inverse_of: :sender_tip_outs
  belongs_to :receiver_calculation, class_name: "Calculation", inverse_of: :receiver_tip_outs
  belongs_to :sender, class_name: "AreaType", inverse_of: :sender_tip_outs
  belongs_to :receiver, class_name: "AreaType", inverse_of: :receiver_tip_outs
  belongs_to :shift_type

  field :percentage, type: Float, default: 0
  field :cc_summ, type: Float
  field :cash_summ, type: Float
  field :date, type: Date

  before_save :set_receiver_calculation
  after_save :recalculate_receiver_calculation
  after_destroy :set_calculation_blanks
  after_destroy :recalculate_calculations

  validates :sender_calculation, :sender, :receiver, :shift_type, :percentage, :date, presence: true
  # TODO: :receiver_calculation, :cc_summ, :cash_summ - now can be nil.

  def calculate_summs
    self.cc_summ = sender_calculation.total_cc_tips*percentage/100
    self.cash_summ = sender_calculation.total_cash_tips*percentage/100

    save

    sender_calculation.recalculate_tipouts
  end

  def recalculate_receiver_calculation
    if receiver_calculation
      receiver_calculation.recalculate_tipouts
    end
  end

  def recalculate_calculations
    receiver_calculation.recalculate if receiver_calculation
    sender_calculation.recalculate if sender_calculation
  end

  def set_receiver_calculation
    r = sender_calculation.restaurant # TODO: add restaurant to TipOut
    if c = r.calculations.where(date: date, shift_type_id: shift_type_id, area_type_id: receiver_id).first
      self.receiver_calculation = c
    end
  end

  def recalculate_previous_calculation(area, shift)
    r = sender_calculation.restaurant # TODO: add restaurant to TipOut

    if c = r.calculations.where(
        date: date,
        shift_type_id: shift,
        area_type_id: area
      ).first

      c.recalculate
    end
  end

  def set_calculation_blanks
    sender_calculation.reload.set_filled_attribute if sender_calculation
    receiver_calculation.reload.set_filled_attribute if receiver_calculation
  end
end