require "rails_helper"

describe Restaurant do
  let!(:restaurant) { FactoryGirl.create(:seeded_restaurant, user: FactoryGirl.create(:user)) }

  it "should create fullfilled restaurant" do
    expect( restaurant.area_types.count ).to eq(3)
    expect( restaurant.shift_types.count ).to eq(3)
    expect( restaurant.position_types.count ).to eq(3)
    expect( restaurant.area_shifts.count ).to eq(9)

    restaurant.area_shifts.each do |area_shift|
      expect( area_shift.days ).to eq(AreaShift::DAYS)
    end
  end
end