require "rails_helper"

describe DayCalculation do
  let!(:restaurant) { FactoryGirl.create(:seeded_restaurant, user: FactoryGirl.create(:user)) }

  xit "lock feature"
end