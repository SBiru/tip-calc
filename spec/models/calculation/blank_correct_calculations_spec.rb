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

  context "#correct field logic" do
    let!(:percantage_1) { calculation.percent_distributions[0] }
    let!(:percantage_2) { calculation.percent_distributions[1] }
    let!(:percantage_3) { calculation.percent_distributions[2] }

    let!(:employee_1_1) { percantage_1.position_type.employees.first }
    let!(:employee_1_2) { percantage_1.position_type.employees.second }
    let!(:employee_2_1) { percantage_2.position_type.employees.first }
    let!(:employee_3_1) { percantage_3.position_type.employees.first }
    let!(:employee_3_2) { percantage_3.position_type.employees.second }

    let!(:area_2) { restaurant.area_types.last }

    before :each do
      percantage_1.update(percentage: 100)
      percantage_1.save

      @employee_distribution = calculation.employee_distributions.create(
        employee: employee_1_1,
        cc_tips: 100,
        cash_tips: 100,
        position_type: percantage_1.position_type,
        area_type: calculation.area_type,
        hours_worked: 10,
        team_number: 1
      )
      calculation.recalculate
    end

    it "should be correct" do
      expect(calculation.is_calculation_correct?).to eq(true)
      expect(calculation.correct?).to eq(true)
    end

    it "should not be correct is hours worked is 0" do
      @employee_distribution.hours_worked = 0
      @employee_distribution.save
      calculation.recalculate
      expect(calculation.is_calculation_correct?).to eq(false)
      expect(calculation.correct?).to eq(false)
    end

    # it "should not be correct if collected tips is 0" do
    #   @employee_distribution.cash_tips = 0
    #   @employee_distribution.cc_tips = 0
    #   calculation.recalculate
    #   expect(calculation.is_calculation_correct?).to eq(false)
    #   expect(calculation.correct?).to eq(false)
    # end

    it "should not be correct if total percantage is 0" do
      percantage_1.percentage = 0
      percantage_1.save
      calculation.recalculate
      expect(calculation.is_calculation_correct?).to eq(false)
      expect(calculation.correct?).to eq(false)
    end

    it "should not be correct if total percantage less than 100" do
      percantage_1.percentage = 59
      percantage_1.save
      calculation.recalculate
      expect(calculation.is_calculation_correct?).to eq(false)
      expect(calculation.correct?).to eq(false)
    end

    # it "should not be correct if employee distributions none" do
    #   calculation.employee_distributions.destroy_all
    #   calculation.reload
    #   calculation.recalculate
    #   expect(calculation.is_calculation_correct?).to eq(false)
    #   expect(calculation.correct?).to eq(false)
    # end

    it "should not be correct if pending distributions present" do
      EmployeeDistribution.create(
        restaurant: calculation.restaurant,
        date: calculation.date,
        area_type: calculation.area_type,
        shift_type: calculation.shift_type,
        position_type: percantage_3.position_type,
        employee: employee_3_1,
        team_number: 1,
        cash_tips: 100,
        cc_tips: 100,
        status: "pending",
        is_a_source_distribution: true
      )

      calculation.recalculate
      expect(calculation.is_calculation_correct?).to eq(false)
      expect(calculation.correct?).to eq(false)
    end

    describe "points calculations" do
      before :each do
        calculation.distribution_type = "points"
        calculation.save
      end

      it "should not be correct if total percantage is 0" do
        percantage_1.percentage = 0
        percantage_1.save
        calculation.recalculate
        expect(calculation.is_calculation_correct?).to eq(false)
        expect(calculation.correct?).to eq(false)
      end

      it "should not be correct if total percantage less than 100" do
        percantage_1.percentage = 59
        percantage_1.save
        calculation.recalculate
        expect(calculation.is_calculation_correct?).to eq(true)
        expect(calculation.correct?).to eq(true)
      end
    end
  end

  context "#blank logic fields" do

    let!(:percantage_1) { calculation.percent_distributions[0] }
    let!(:percantage_2) { calculation.percent_distributions[1] }
    let!(:percantage_3) { calculation.percent_distributions[2] }

    let!(:employee_1_1) { percantage_1.position_type.employees.first }
    let!(:employee_1_2) { percantage_1.position_type.employees.second }
    let!(:employee_2_1) { percantage_2.position_type.employees.first }
    let!(:employee_3_1) { percantage_3.position_type.employees.first }
    let!(:employee_3_2) { percantage_3.position_type.employees.second }

    let!(:area_2) { restaurant.area_types.last }

    it "should be correct" do
      expect(calculation.is_blank?).to eq(true)
      expect(calculation.filled?).to eq(false)
    end

    describe "employee_distribution persist" do
      before :each do
        @employee_distribution = calculation.employee_distributions.create(
          employee: employee_1_1,
          cc_tips: 100,
          cash_tips: 100,
          position_type: percantage_1.position_type,
          area_type: calculation.area_type,
          hours_worked: 10,
          team_number: 1
        )
      end

      it "should be correct" do
        calculation.recalculate
        expect(calculation.is_blank?).to eq(false)
        expect(calculation.filled?).to eq(true)
      end
    end

    it "should not be blank if total percantage less than 100" do
      percantage_1.percentage = 59
      percantage_1.save
      calculation.recalculate
      expect(calculation.is_blank?).to eq(false)
      expect(calculation.filled?).to eq(true)
    end

    it "should not be blank if total percantage less than 100" do
      calculation.pos_total = 100
      calculation.save
      calculation.recalculate
      expect(calculation.is_blank?).to eq(false)
      expect(calculation.filled?).to eq(true)
    end

    describe "tip outs sent" do
      before :each do
        receiver_area = restaurant.area_types.last.id
        @tip_out = calculation.sender_tip_outs.find_or_create_by(
          sender_calculation_id: calculation.id,
          receiver_id: receiver_area,
          sender_id: calculation.area_type.id,
          date: calculation.date,
          shift_type: calculation.shift_type
        )
      end

      it "should not be blank if total percantage less than 100" do
        calculation.recalculate
        expect(calculation.is_blank?).to eq(false)
        expect(calculation.filled?).to eq(true)
      end
    end

    describe "received tip outs exist" do
      let!(:sender_calculation) { FactoryGirl.create(:calculation,
        restaurant: restaurant.reload,
        user: restaurant.user,
        shift_type: restaurant.shift_types.last,
        area_type: restaurant.area_types.last,
        source_positions: [restaurant.position_types.last],
        distribution_type: "percents"
      )
      }

      before :each do
        receiver_area = restaurant.area_types.last.id
        @tip_out = sender_calculation.sender_tip_outs.find_or_create_by(
          sender_calculation_id: sender_calculation.id,
          receiver_id: calculation.area_type,
          sender_id: sender_calculation.area_type.id,
          date: sender_calculation.date,
          shift_type: sender_calculation.shift_type,
          receiver_calculation: calculation
        )
      end

      it "should not be blank if total percantage less than 100" do
        calculation.recalculate
        expect(calculation.is_blank?).to eq(false)
        expect(calculation.filled?).to eq(true)
      end
    end

    it "should not be blank if pending distributions present" do
      EmployeeDistribution.create(
        restaurant: calculation.restaurant,
        date: calculation.date,
        area_type: calculation.area_type,
        shift_type: calculation.shift_type,
        position_type: percantage_3.position_type,
        employee: employee_3_1,
        team_number: 1,
        cash_tips: 100,
        cc_tips: 100,
        status: "pending",
        is_a_source_distribution: true
      )

      calculation.recalculate
      expect(calculation.is_blank?).to eq(false)
      expect(calculation.filled?).to eq(true)
    end

    it "should not be blank if pending distributions created without recalculation" do
      EmployeeDistribution.create(
        restaurant: calculation.restaurant,
        date: calculation.date,
        area_type: calculation.area_type,
        shift_type: calculation.shift_type,
        position_type: percantage_3.position_type,
        employee: employee_3_1,
        team_number: 1,
        cash_tips: 100,
        cc_tips: 100,
        status: "pending",
        is_a_source_distribution: true
      )

      calculation.reload

      expect(calculation.is_blank?).to eq(false)
      expect(calculation.filled?).to eq(true)
    end

    it "should not be blank if pending distributions present" do
      ed = EmployeeDistribution.create(
        restaurant: calculation.restaurant,
        date: calculation.date,
        area_type: calculation.area_type,
        shift_type: calculation.shift_type,
        position_type: percantage_3.position_type,
        employee: employee_3_1,
        team_number: 1,
        cash_tips: 100,
        cc_tips: 100,
        status: "pending",
        is_a_source_distribution: true
      )

      calculation.recalculate
      ed.destroy
      calculation.reload
      expect(calculation.is_blank?).to eq(true)
      expect(calculation.filled?).to eq(false)
    end
  end
end
