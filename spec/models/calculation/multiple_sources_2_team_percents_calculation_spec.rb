require "rails_helper"

describe Calculation do
  let!(:restaurant) { FactoryGirl.create(:seeded_restaurant, user: FactoryGirl.create(:user)) }
  let!(:calculation) { FactoryGirl.create(:calculation,
    restaurant: restaurant.reload,
    user: restaurant.user,
    shift_type: restaurant.shift_types.first,
    area_type: restaurant.area_types.first,
    source_position_ids: [restaurant.position_types.first.id.to_s, restaurant.position_types.second.id.to_s],
    distribution_type: "percents",
    teams_quantity: 2
  )
  }

  context "Multiple sources present" do
    let!(:percantage_1) { calculation.percent_distributions[0] }
    let!(:percantage_2) { calculation.percent_distributions[1] }
    let!(:percantage_3) { calculation.percent_distributions[2] }

    let!(:employee_1_1) { percantage_1.position_type.employees.first }
    let!(:employee_1_2) { percantage_1.position_type.employees.second }
    let!(:employee_1_3) { percantage_1.position_type.employees.third }

    let!(:employee_2_1) { percantage_2.position_type.employees.first }
    let!(:employee_2_2) { percantage_2.position_type.employees.second }
    let!(:employee_2_3) { percantage_2.position_type.employees.third }

    let!(:employee_3_1) { percantage_3.position_type.employees.first }

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
                                "hoursWorkedInHours" => "2.5",
                                "totalMoneyIn" => {
                                    "cc" => "100",
                                    "cash" => "0"
                                },
                                "totalMoneyOut" => {},
                                "totalTipOutsGiven" => {},
                                "totalTipOutsReceived" => {},
                                "finalMoneyToDistribute" => {}
                            },
                            "#{ employee_1_2.id }" => {
                                "hoursWorkedInHours" => "7.5",
                                "totalMoneyIn" => {
                                    "cc" => "0",
                                    "cash" => "10"
                                },
                                "totalMoneyOut" => {},
                                "totalTipOutsGiven" => {},
                                "totalTipOutsReceived" => {},
                                "finalMoneyToDistribute" => {}
                            }
                        }
                    },
                    "2" => {
                        "employees" => {
                            "#{ employee_1_3.id }" => {
                                "hoursWorkedInHours" => "10",
                                "totalMoneyIn" => {
                                    "cc" => "200",
                                    "cash" => "20"
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
                                "hoursWorkedInHours" => "2.5",
                                "totalMoneyIn" => {
                                    "cc" => "300",
                                    "cash" => "0"
                                },
                                "totalMoneyOut" => {},
                                "totalTipOutsGiven" => {},
                                "totalTipOutsReceived" => {},
                                "finalMoneyToDistribute" => {}
                            },
                            "#{ employee_2_2.id }" => {
                                "hoursWorkedInHours" => "7.5",
                                "totalMoneyIn" => {
                                    "cc" => "0",
                                    "cash" => "30"
                                },
                                "totalMoneyOut" => {},
                                "totalTipOutsGiven" => {},
                                "totalTipOutsReceived" => {},
                                "finalMoneyToDistribute" => {}
                            }
                        }
                    },
                    "2" => {
                        "employees" => {
                            "#{ employee_2_3.id }" => {
                                "hoursWorkedInHours" => "10",
                                "totalMoneyIn" => {
                                    "cc" => "400",
                                    "cash" => "40"
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
                                "hoursWorkedInHours" => "10",
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
        "tips" => {
            "given" => {
                "#{ area_2.name }" => {
                       "area_type_id" => area_2.id,
                    "percentage" => "50.00"
                }
            }
        },
        "percentage" => {
            "#{ percantage_1.id }" => "50",
            "#{ percantage_2.id }" => "30",
            "#{ percantage_3.id }" => "20",
        },
        "id" => calculation.id
      }

      calculation.update_calculation(@params)
    end

    it "should have 7 employee distributions" do
      expect(calculation.employee_distributions.count).to eq(7)
    end

    it "should have right input money numbers in employee distributions for source type" do

      # 1 team

      ed_1_1 = calculation.employee_distributions.where(employee: employee_1_1).first

      expect(ed_1_1.cc_tips.round(2)).to eq(100)
      expect(ed_1_1.cash_tips.round(2)).to eq(0)

      ed_1_2 = calculation.employee_distributions.where(employee: employee_1_2).first

      expect(ed_1_2.cc_tips.round(2)).to eq(0)
      expect(ed_1_2.cash_tips.round(2)).to eq(10)

      ed_1_3 = calculation.employee_distributions.where(employee: employee_1_3).first

      expect(ed_1_3.cc_tips.round(2)).to eq(200)
      expect(ed_1_3.cash_tips.round(2)).to eq(20)

      # 2 team

      ed_2_1 = calculation.employee_distributions.where(employee: employee_2_1).first

      expect(ed_2_1.cc_tips.round(2)).to eq(300)
      expect(ed_2_1.cash_tips.round(2)).to eq(0)

      ed_2_2 = calculation.employee_distributions.where(employee: employee_2_2).first

      expect(ed_2_2.cc_tips.round(2)).to eq(0)
      expect(ed_2_2.cash_tips.round(2)).to eq(30)

      ed_2_3 = calculation.employee_distributions.where(employee: employee_2_3).first

      expect(ed_2_3.cc_tips.round(2)).to eq(400)
      expect(ed_2_3.cash_tips.round(2)).to eq(40)
    end

    # 1 team

    it "should have right numbers for 1.1 employee distribution" do
      ed_1_1 = calculation.employee_distributions.where(employee: employee_1_1).first

      expect(ed_1_1.cc_tips_distr.round(2)).to eq(41.67)
      # expect(ed_1.cash_tips_distr.round(2)).to eq(15)
      # expect(ed_1.cc_tips_distr_final.round(2)).to eq(20)
      # expect(ed_1.cash_tips_distr_final.round(2)).to eq(15)
      # expect(ed_1.tip_outs_given_cc.round(2)).to eq(0)
      # expect(ed_1.tip_outs_given_cash.round(2)).to eq(0)
      # expect(ed_1.tip_outs_received_cc.round(2)).to eq(0)
      # expect(ed_1.tip_outs_received_cash.round(2)).to eq(0)
    end

    it "should have right numbers for 1.2 employee distribution" do
      ed_1_2 = calculation.employee_distributions.where(employee: employee_1_2).first

      expect(ed_1_2.cc_tips_distr.round(2)).to eq(125)
      # expect(ed_2.cash_tips_distr.round(2)).to eq(15)
      # expect(ed_2.cc_tips_distr_final.round(2)).to eq(20)
      # expect(ed_2.cash_tips_distr_final.round(2)).to eq(15)
      # expect(ed_2.tip_outs_given_cc.round(2)).to eq(0)
      # expect(ed_2.tip_outs_given_cash.round(2)).to eq(0)
      # expect(ed_2.tip_outs_received_cc.round(2)).to eq(0)
      # expect(ed_2.tip_outs_received_cash.round(2)).to eq(0)
    end

    it "should have right numbers for 1.3 employee distribution" do
      ed_1_3 = calculation.employee_distributions.where(employee: employee_1_3).first

      expect(ed_1_3.cc_tips_distr.round(2)).to eq(333.33)
      # expect(ed_3.cash_tips_distr.round(2)).to eq(45)
      # expect(ed_3.cc_tips_distr_final.round(2)).to eq(60)
      # expect(ed_3.cash_tips_distr_final.round(2)).to eq(45)
      # expect(ed_3.tip_outs_given_cc.round(2)).to eq(0)
      # expect(ed_3.tip_outs_given_cash.round(2)).to eq(0)
      # expect(ed_3.tip_outs_received_cc.round(2)).to eq(0)
      # expect(ed_3.tip_outs_received_cash.round(2)).to eq(0)
    end

    # 2 team

    it "should have right numbers for 2.1 employee distribution" do
      ed_2_1 = calculation.employee_distributions.where(employee: employee_2_1).first

      expect(ed_2_1.cc_tips_distr.round(2)).to eq(32.14)
      # expect(ed_1.cash_tips_distr.round(2)).to eq(15)
      # expect(ed_1.cc_tips_distr_final.round(2)).to eq(20)
      # expect(ed_1.cash_tips_distr_final.round(2)).to eq(15)
      # expect(ed_1.tip_outs_given_cc.round(2)).to eq(0)
      # expect(ed_1.tip_outs_given_cash.round(2)).to eq(0)
      # expect(ed_1.tip_outs_received_cc.round(2)).to eq(0)
      # expect(ed_1.tip_outs_received_cash.round(2)).to eq(0)
    end

    it "should have right numbers for 2.2 employee distribution" do
      ed_2_2 = calculation.employee_distributions.where(employee: employee_2_2).first

      expect(ed_2_2.cc_tips_distr.round(2)).to eq(96.43)
      # expect(ed_2.cash_tips_distr.round(2)).to eq(15)
      # expect(ed_2.cc_tips_distr_final.round(2)).to eq(20)
      # expect(ed_2.cash_tips_distr_final.round(2)).to eq(15)
      # expect(ed_2.tip_outs_given_cc.round(2)).to eq(0)
      # expect(ed_2.tip_outs_given_cash.round(2)).to eq(0)
      # expect(ed_2.tip_outs_received_cc.round(2)).to eq(0)
      # expect(ed_2.tip_outs_received_cash.round(2)).to eq(0)
    end

    it "should have right numbers for 2.3 employee distribution" do
      ed_2_3 = calculation.employee_distributions.where(employee: employee_2_3).first

      expect(ed_2_3.cc_tips_distr.round(2)).to eq(171.43)
      # expect(ed_3.cash_tips_distr.round(2)).to eq(45)
      # expect(ed_3.cc_tips_distr_final.round(2)).to eq(60)
      # expect(ed_3.cash_tips_distr_final.round(2)).to eq(45)
      # expect(ed_3.tip_outs_given_cc.round(2)).to eq(0)
      # expect(ed_3.tip_outs_given_cash.round(2)).to eq(0)
      # expect(ed_3.tip_outs_received_cc.round(2)).to eq(0)
      # expect(ed_3.tip_outs_received_cash.round(2)).to eq(0)
    end

    it "should have right numbers for 3.1 employee distribution" do
      ed_3_1 = calculation.employee_distributions.where(employee: employee_3_1).first

      expect(ed_3_1.cc_tips_distr.round(2)).to eq(200)
      # expect(ed_4.cash_tips_distr.round(2)).to eq(75)
      # expect(ed_4.cc_tips_distr_final.round(2)).to eq(100)
      # expect(ed_4.cash_tips_distr_final.round(2)).to eq(75)
      # expect(ed_4.tip_outs_given_cc.round(2)).to eq(0)
      # expect(ed_4.tip_outs_given_cash.round(2)).to eq(0)
      # expect(ed_4.tip_outs_received_cc.round(2)).to eq(0)
      # expect(ed_4.tip_outs_received_cash.round(2)).to eq(0)
    end

    it "#total_tip_outs_given_percentage" do
      expect(calculation.total_tip_outs_given_percentage).to eq(50)
    end

    it "#total_tip_outs_given_cc" do
      expect(calculation.total_tip_outs_given_cc.round(2)).to eq(500)
    end

    it "#total_tip_outs_given_cash" do
      expect(calculation.total_tip_outs_given_cash.round(2)).to eq(50)
    end

    it "#total_tip_outs_received_cc" do
      expect(calculation.total_tip_outs_received_cc.round(2)).to eq(0)
    end

    it "#total_tip_outs_received_cash" do
      expect(calculation.total_tip_outs_received_cash.round(2)).to eq(0)
    end

    it "#total_tips_distributed_cc" do
      expect(calculation.total_tips_distributed_cc.round(2)).to eq(500)
    end

    it "#total_tips_distributed_cash" do
      expect(calculation.total_tips_distributed_cash.round(2)).to eq(50)
    end

    it "#total_tips_distributed_global" do
      expect(calculation.total_tips_distributed_global.round(2)).to eq(550)
    end
  end
end
