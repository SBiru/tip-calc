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

  context "when pending distribution created first" do
    before :each do 
      @ed = EmployeeDistribution.create(
        restaurant: restaurant,
        date: Time.zone.now.to_date + 3.days,
        area_type: restaurant.area_types.first,
        shift_type: restaurant.shift_types.first,
        employee: restaurant.employees.first,
        position_type: restaurant.position_types.first,
        team_number: 1,
        cash_tips: 100,
        cc_tips: 100,
        status: "pending",
        is_a_source_distribution: true
      )

      @first_position = restaurant.position_types.first
    end

    it "should be 1 pending distribution persisted" do
      expect(restaurant.employee_distributions.pending.include?(@ed)).to eq(true)
    end

    it "should create calculation" do
      expect(restaurant.reload.calculations.count).to eq(2)
    end

    it "should create calculation" do
      calc = restaurant.calculations.where(
        date: Time.zone.now.to_date + 3.days,
        area_type: restaurant.area_types.first,
        shift_type: restaurant.shift_types.first,
        teams_quantity: 1,
        source_position_type_name_string: @first_position.name,
      ).first

      expect(calc.pending_distributions.count).to eq(1)
    end

    it "should have pending distribution" do
      calc = restaurant.calculations.where(
        date: Time.zone.now.to_date + 3.days,
        area_type: restaurant.area_types.first,
        shift_type: restaurant.shift_types.first,
        teams_quantity: 1,
        source_position_type_name_string: @first_position.name,
      ).first
      expect(calc.pending_distributions.include?(@ed)).to eq(true)
    end

    it "should create blank calculation for pending distribution" do
      calculation = restaurant.calculations.where(
        date: Time.zone.now.to_date + 3.days,
        area_type: restaurant.area_types.first,
        shift_type: restaurant.shift_types.first,
        teams_quantity: 1,
        source_position_type_name_string: @first_position.name,
      ).first
      expect(calculation.nil?).to eq(false)
    end

    it "should create blank calculation and set blank and correct values" do
      calculation = restaurant.calculations.where(
        date: Time.zone.now.to_date + 3.days, 
        area_type: restaurant.area_types.first,
        shift_type: restaurant.shift_types.first,
        teams_quantity: 1,
        source_position_type_name_string: @first_position.name,
      ).first
      expect(calculation.is_blank?).to eq(false)
      expect(calculation.filled?).to eq(true)
    end

    it "should create blank calculation and set blank and correct values" do
      calculation = restaurant.calculations.where(
        date: Time.zone.now.to_date + 3.days, 
        area_type: restaurant.area_types.first,
        shift_type: restaurant.shift_types.first,
        teams_quantity: 1,
        source_position_type_name_string: @first_position.name,
      ).first
      expect(calculation.is_calculation_correct?).to eq(false)
      expect(calculation.correct?).to eq(false)
    end
  end
end
