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

  context "Multiple sources present" do
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

      calculation.source_positions = [percantage_1.position_type, percantage_2.position_type]
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
                            "#{ employee_1_1.id }" => {
                                "hoursWorkedInHours" => "1",
                                "totalMoneyIn" => {
                                    "cc" => "100",
                                    "cash" => "50"
                                },
                                "totalMoneyOut" => {},
                                "totalTipOutsGiven" => {},
                                "totalTipOutsReceived" => {},
                                "finalMoneyToDistribute" => {}
                            },
                            "#{ employee_1_2.id }" => {
                                "hoursWorkedInHours" => "1",
                                "totalMoneyIn" => {
                                    "cc" => "50",
                                    "cash" => "25"
                                },
                                "totalMoneyOut" => {},
                                "totalTipOutsGiven" => {},
                                "totalTipOutsReceived" => {},
                                "finalMoneyToDistribute" => {}
                            }
                        }
                    }
                }
            },
            "#{ percantage_2.position_type.name }" => {
                "positionTypeIsASource" => "true",
                "teams" => {
                    "1" => {
                        "employees" => {
                            "#{ employee_2_1.id }" => {
                                "hoursWorkedInHours" => "2",
                                "totalMoneyIn" => {
                                    "cc" => "50",
                                    "cash" => "75"
                                },
                                "totalMoneyOut" => {},
                                "totalTipOutsGiven" => {},
                                "totalTipOutsReceived" => {},
                                "finalMoneyToDistribute" => {}
                            }
                        }
                    }
                }
            },
            "#{ percantage_3.position_type.name }" => {
                "positionTypeIsASource" => "false",
                "teams" => {
                    "1" => {
                        "employees" => {
                            "#{ employee_3_1.id }" => {
                                "hoursWorkedInHours" => "1",
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
        # "tips" => {
        #     "given" => {
        #         "#{ area_2.name }" => {
        #                "area_id" => area_2.id,
        #             "percentage" => "5.00"
        #         }
        #     }
        # },
        "percentage" => {
            "#{ percantage_1.id }" => "20",
            "#{ percantage_2.id }" => "30",
            "#{ percantage_3.id }" => "50",
        },
        "id" => calculation.id
      }

      calculation.update_calculation(@params)
    end

    it "should have 5 employee distributions" do
      expect(calculation.employee_distributions.count).to eq(4)
    end

    it "should have right input money numbers in employee distributions for source type" do
      ed_1 = calculation.employee_distributions.where(employee: employee_1_1).first

      expect(ed_1.cc_tips.round(2)).to eq(100)
      expect(ed_1.cash_tips.round(2)).to eq(50)

      ed_2 = calculation.employee_distributions.where(employee: employee_1_2).first

      expect(ed_2.cc_tips.round(2)).to eq(50)
      expect(ed_2.cash_tips.round(2)).to eq(25)

      ed_3 = calculation.employee_distributions.where(employee: employee_2_1).first

      expect(ed_3.cc_tips.round(2)).to eq(50)
      expect(ed_3.cash_tips.round(2)).to eq(75)
    end

    it "should have right numbers for 1.1 employee distribution" do
      ed_1 = calculation.employee_distributions.where(employee: employee_1_1).first

      expect(ed_1.cc_tips_distr.round(2)).to eq(20)
      expect(ed_1.cash_tips_distr.round(2)).to eq(15)
      expect(ed_1.cc_tips_distr_final.round(2)).to eq(20)
      expect(ed_1.cash_tips_distr_final.round(2)).to eq(15)
      expect(ed_1.tip_outs_given_cc.round(2)).to eq(0)
      expect(ed_1.tip_outs_given_cash.round(2)).to eq(0)
      expect(ed_1.tip_outs_received_cc.round(2)).to eq(0)
      expect(ed_1.tip_outs_received_cash.round(2)).to eq(0)
    end

    it "should have right numbers for 1.2 employee distribution" do
      ed_2 = calculation.employee_distributions.where(employee: employee_1_2).first

      expect(ed_2.cc_tips_distr.round(2)).to eq(20)
      expect(ed_2.cash_tips_distr.round(2)).to eq(15)
      expect(ed_2.cc_tips_distr_final.round(2)).to eq(20)
      expect(ed_2.cash_tips_distr_final.round(2)).to eq(15)
      expect(ed_2.tip_outs_given_cc.round(2)).to eq(0)
      expect(ed_2.tip_outs_given_cash.round(2)).to eq(0)
      expect(ed_2.tip_outs_received_cc.round(2)).to eq(0)
      expect(ed_2.tip_outs_received_cash.round(2)).to eq(0)
    end

    it "should have right numbers for 1.2 employee distribution" do
      ed_3 = calculation.employee_distributions.where(employee: employee_2_1).first

      expect(ed_3.cc_tips_distr.round(2)).to eq(60)
      expect(ed_3.cash_tips_distr.round(2)).to eq(45)
      expect(ed_3.cc_tips_distr_final.round(2)).to eq(60)
      expect(ed_3.cash_tips_distr_final.round(2)).to eq(45)
      expect(ed_3.tip_outs_given_cc.round(2)).to eq(0)
      expect(ed_3.tip_outs_given_cash.round(2)).to eq(0)
      expect(ed_3.tip_outs_received_cc.round(2)).to eq(0)
      expect(ed_3.tip_outs_received_cash.round(2)).to eq(0)
    end

    it "should have right numbers for 1.2 employee distribution" do
      ed_4 = calculation.employee_distributions.where(employee: employee_3_1).first

      expect(ed_4.cc_tips_distr.round(2)).to eq(100)
      expect(ed_4.cash_tips_distr.round(2)).to eq(75)
      expect(ed_4.cc_tips_distr_final.round(2)).to eq(100)
      expect(ed_4.cash_tips_distr_final.round(2)).to eq(75)
      expect(ed_4.tip_outs_given_cc.round(2)).to eq(0)
      expect(ed_4.tip_outs_given_cash.round(2)).to eq(0)
      expect(ed_4.tip_outs_received_cc.round(2)).to eq(0)
      expect(ed_4.tip_outs_received_cash.round(2)).to eq(0)
    end

    it "#total_tip_outs_given_percentage" do
      expect(calculation.total_tip_outs_given_percentage).to eq(0)
    end

    it "#total_tip_outs_given_cc" do
      expect(calculation.total_tip_outs_given_cc.round(2)).to eq(0)
    end

    it "#total_tip_outs_given_cash" do
      expect(calculation.total_tip_outs_given_cash.round(2)).to eq(0)
    end

    it "#total_tip_outs_received_cc" do
      expect(calculation.total_tip_outs_received_cc.round(2)).to eq(0)
    end

    it "#total_tip_outs_received_cash" do
      expect(calculation.total_tip_outs_received_cash.round(2)).to eq(0)
    end

    it "#total_tips_distributed_cc" do
      expect(calculation.total_tips_distributed_cc.round(2)).to eq(200)
    end

    it "#total_tips_distributed_cash" do
      expect(calculation.total_tips_distributed_cash.round(2)).to eq(150)
    end

    it "#total_tips_distributed_global" do
      expect(calculation.total_tips_distributed_global.round(2)).to eq(350)
    end
  end
end
