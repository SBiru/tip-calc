
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

  it "should have related position types" do
    expect(calculation).to be_valid
  end

  it "should have related position types" do
    expect(calculation.persisted?).to eq(true)
  end

  it "should have related position types" do
    expect(calculation.position_types.count).to eq(3)
  end

  it "should have used position types" do
    expect(calculation.used_position_types.count).to eq(3)
  end

  it "should have percent distributions after create" do
    expect(calculation.percent_distributions.count).to eq(3)
  end

  it "should not create duplicate calculation" do
    c = FactoryGirl.build(:calculation,
      restaurant: restaurant.reload,
      user: restaurant.user,
      shift_type: restaurant.shift_types.first,
      area_type: restaurant.area_types.first,
      source_position_ids: [restaurant.position_types.first.id.to_s],
      distribution_type: "percents"
    )

    expect{ c.save }.not_to change{ Calculation.count }
  end

  context "simple calculation without tip outs exist" do

    let!(:percantage_1) { calculation.percent_distributions[0] }
    let!(:percantage_2) { calculation.percent_distributions[1] }
    let!(:percantage_3) { calculation.percent_distributions[2] }

    let!(:employee_1) { percantage_1.position_type.employees.first }
    let!(:employee_2) { percantage_2.position_type.employees.first }
    let!(:employee_3) { percantage_3.position_type.employees.first }

    before :each do

      calculation.source_positions = [percantage_1.position_type]
      calculation.save

      @params = {
        "calculationId" => calculation.id,
        "distribution_type" => "percents",
        "posTotals" => {
            "calculationPosTotal" => "0",
            "dayPosTotal" => "0"
        },

        "positionsMoney" => {
            "#{ percantage_1.position_type.name }" => {
                "positionTypeIsASource" => "true",
                "teams" => {
                    "1" => {
                        "employees" => {
                            "#{ employee_1.id }" => {
                                "hoursWorkedInHours" => "1",
                                "totalMoneyIn" => {
                                    "cc" => "100.0",
                                    "cash" => "200.0"
                                },
                                "totalMoneyOut" => {},
                                "totalTipOutsGiven" => {},
                                "totalTipOutsReceived" => {},
                                "finalMoneyToDistribute" => {}
                            }
                        }
                    }
                }
            }
        },

        "percentage" => {
            "#{ percantage_1.id }" => "100"
        },
        "id" => calculation.id
      }

      calculation.update_calculation(@params)
    end

    it "should have 3 employee distributions" do
      expect(calculation.employee_distributions.count).to eq(1)
    end

    it "should have right input money numbers in employee distributions for source type" do
      ed = calculation.employee_distributions.where(position_type: calculation.source_positions.first).first

      expect(ed.cc_tips).to eq(100)
      expect(ed.cash_tips).to eq(200)
    end

    it "should have right numbers for 1 employee distribution" do
      ed_1 = calculation.employee_distributions[0]

      expect(ed_1.cc_tips_distr).to eq(100)
      expect(ed_1.cash_tips_distr).to eq(200)
      expect(ed_1.cc_tips_distr_final).to eq(100)
      expect(ed_1.cash_tips_distr_final).to eq(200)
    end

    context "tip out exist" do
      let!(:sender_calculation) { FactoryGirl.create(:calculation,
        restaurant: restaurant.reload,
        user: restaurant.user,
        shift_type: restaurant.shift_types.first,
        area_type: restaurant.area_types.last,
        source_positions: [restaurant.position_types.first],
        distribution_type: "percents"
        )
      }

      let!(:tip_out_received) { TipOut.create(
        percentage: 50,
        cc_summ: 60,
        cash_summ: 120,
        receiver_calculation: calculation,
        sender_calculation: sender_calculation,
        date: calculation.date,
        sender: sender_calculation.area_type,
        receiver: calculation.area_type,
        shift_type: calculation.shift_type
        )
      }

      it "should have right tips received cc" do
        employee_distribution = calculation.reload.employee_distributions[0]
        expect(employee_distribution.tip_outs_received_cc).to eq(60)
      end

      it "should have right tips received cash" do
        employee_distribution = calculation.reload.employee_distributions[0]
        expect(employee_distribution.tip_outs_received_cash).to eq(120)
      end

      it "should have right tips total distributed cc" do
        employee_distribution = calculation.reload.employee_distributions[0]
        expect(employee_distribution.cc_tips_distr_final).to eq(160)
      end

      it "should have right tips total distributed cash" do
        employee_distribution = calculation.reload.employee_distributions[0]
        expect(employee_distribution.cash_tips_distr_final).to eq(320)
      end

      it "should be receiver_calculation" do
        expect(calculation.receiver_tip_outs.include?(tip_out_received)).to eq(true)
      end

      context "tip out changed" do
        before :each do
          tip_out_received.cc_summ = 30
          tip_out_received.cash_summ = 60
          tip_out_received.save
        end

        it "should have right tips received cc" do
          employee_distribution = calculation.reload.employee_distributions[0]
          expect(employee_distribution.tip_outs_received_cc).to eq(30)
          expect(employee_distribution.tip_outs_received_cash).to eq(60)
          expect(employee_distribution.cc_tips_distr_final).to eq(130)
          expect(employee_distribution.cash_tips_distr_final).to eq(260)
        end
      end

      context "tip out destroyed" do
        before :each do
          tip_out_received.destroy
        end

        it "should have right numbers for 1 employee distribution" do
          ed_1 = calculation.employee_distributions[0]

          expect(ed_1.cc_tips_distr).to eq(100)
          expect(ed_1.cash_tips_distr).to eq(200)
          expect(ed_1.cc_tips_distr_final).to eq(100)
          expect(ed_1.cash_tips_distr_final).to eq(200)
        end

        xit "check is sender calculation is being updated"
      end
    end
  end
end