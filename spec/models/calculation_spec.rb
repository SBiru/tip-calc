require "rails_helper"

describe Calculation do
  let!(:restaurant) { FactoryGirl.create(:seeded_restaurant, user: FactoryGirl.create(:user)) }
  let!(:calculation) { FactoryGirl.create(:calculation,
    restaurant: restaurant.reload,
    user: restaurant.user,
    shift_type: restaurant.shift_types.first,
    area_type: restaurant.area_types.first,
    source_position_ids: [restaurant.position_types.first.id.to_s],
    distribution_type: "percents"
  )
  }

  # TODO:

  # xit "should have 4 used position types when source type is new for this calc" do
  #   expect(calculation.used_position_types.count).to eq(3)
  # end
  # xit "calculation with multiple teams"
  # xit "calculation with multiple employees in 1 team"
  # xit "calculation by POINTS without tipouts exist"
  # xit "calculation by POINTS with tipouts exist"
  # xit "#create_day_calculation"
  # xit "#create_day_area_calculation"
  # xit "#related_employees"
  # xit "Calculation#build_by"
  # xit "#create_percent_distributions"
  # xit "#total_cc_tips"
  # xit "#total_cash_tips"
  # xit "#total_collected_tips"

  # xit "#is_blank?"
  # xit "#recalculate"
  # xit "#report_by"
  # context "Tip Outs logic"
  # context "Sumit logic" do
  #   xit "#pending_distributions"
  # end
  # context "Duplicated logic" do
  #   xit "#duplicate"
  # end
end
