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
            },
            "#{ percantage_2.position_type.name }" => {
                "positionTypeIsASource" => "false",
                "teams" => {
                    "1" => {
                        "employees" => {
                            "#{ employee_2.id }" => {
                                "hoursWorkedInHours" => "1",
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
                            "#{ employee_3.id }" => {
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

        "percentage" => {
            "#{ percantage_1.id }" => "30",
            "#{ percantage_2.id }" => "20",
            "#{ percantage_3.id }" => "50",
        },
        "id" => calculation.id
      }

      calculation.update_calculation(@params)
    end

    it "should have 3 employee distributions" do
      expect(calculation.employee_distributions.count).to eq(3)
    end

    it "should have right input money numbers in employee distributions for source type" do
      ed = calculation.employee_distributions.where(position_type: calculation.source_positions.first).first

      expect(ed.cc_tips).to eq(100)
      expect(ed.cash_tips).to eq(200)
    end

    it "should have right numbers for 1 employee distribution" do
      ed_1 = calculation.employee_distributions[0]

      expect(ed_1.cc_tips_distr).to eq(30)
      expect(ed_1.cash_tips_distr).to eq(60)
      expect(ed_1.cc_tips_distr_final).to eq(30)
      expect(ed_1.cash_tips_distr_final).to eq(60)
    end

    it "should have right numbers for 2 employee distribution" do
      ed_2 = calculation.employee_distributions[1]

      expect(ed_2.cc_tips_distr).to eq(20)
      expect(ed_2.cash_tips_distr).to eq(40)
      expect(ed_2.cc_tips_distr_final).to eq(20)
      expect(ed_2.cash_tips_distr_final).to eq(40)
    end

    it "should have right numbers for 3 employee distribution" do
      ed_3 = calculation.employee_distributions[2]

      expect(ed_3.cc_tips_distr).to eq(50)
      expect(ed_3.cash_tips_distr).to eq(100)
      expect(ed_3.cc_tips_distr_final).to eq(50)
      expect(ed_3.cash_tips_distr_final).to eq(100)
    end

    it "#total_tip_outs_given_percentage" do
      expect(calculation.total_tip_outs_given_percentage).to eq(0)
    end

    it "#total_tip_outs_given_cc" do
      expect(calculation.total_tip_outs_given_cc).to eq(0)
    end

    it "#total_tip_outs_given_cash" do
      expect(calculation.total_tip_outs_given_cash).to eq(0)
    end

    it "#total_tip_outs_received_cc" do
      expect(calculation.total_tip_outs_received_cc).to eq(0)
    end

    it "#total_tip_outs_received_cash" do
      expect(calculation.total_tip_outs_received_cash).to eq(0)
    end

    it "#total_tips_distributed_cc" do
      expect(calculation.total_tips_distributed_cc).to eq(100)
    end

    it "#total_tips_distributed_cash" do
      expect(calculation.total_tips_distributed_cash).to eq(200)
    end

    it "#total_tips_distributed_global" do
      expect(calculation.total_tips_distributed_global).to eq(300)
    end
  end

  context "blank calculation without hours and collected money" do

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
                                "hoursWorkedInHours" => "0",
                                "totalMoneyIn" => {
                                    "cc" => "0.0",
                                    "cash" => "0.0"
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
                "positionTypeIsASource" => "false",
                "teams" => {
                    "1" => {
                        "employees" => {
                            "#{ employee_2.id }" => {
                                "hoursWorkedInHours" => "0",
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
                            "#{ employee_3.id }" => {
                                "hoursWorkedInHours" => "0",
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
            "#{ percantage_1.id }" => "30",
            "#{ percantage_2.id }" => "20",
            "#{ percantage_3.id }" => "50",
        },
        "id" => calculation.id
      }

      calculation.update_calculation(@params)
    end

    it "should have 3 employee distributions" do
      expect(calculation.employee_distributions.count).to eq(3)
    end

    it "should have right input money numbers in employee distributions for source type" do
      ed = calculation.employee_distributions.where(position_type: calculation.source_positions.first).first

      expect(ed.cc_tips).to eq(0)
      expect(ed.cash_tips).to eq(0)
    end

    it "should have right numbers for 1 employee distribution" do
      ed_1 = calculation.employee_distributions[0]

      expect(ed_1.cc_tips_distr).to eq(0)
      expect(ed_1.cash_tips_distr).to eq(0)
      expect(ed_1.cc_tips_distr_final).to eq(0)
      expect(ed_1.cash_tips_distr_final).to eq(0)
    end

    it "should have right numbers for 2 employee distribution" do
      ed_2 = calculation.employee_distributions[1]

      expect(ed_2.cc_tips_distr).to eq(0)
      expect(ed_2.cash_tips_distr).to eq(0)
      expect(ed_2.cc_tips_distr_final).to eq(0)
      expect(ed_2.cash_tips_distr_final).to eq(0)
    end

    it "should have right numbers for 3 employee distribution" do
      ed_3 = calculation.employee_distributions[2]

      expect(ed_3.cc_tips_distr).to eq(0)
      expect(ed_3.cash_tips_distr).to eq(0)
      expect(ed_3.cc_tips_distr_final).to eq(0)
      expect(ed_3.cash_tips_distr_final).to eq(0)
    end

    it "#total_tip_outs_given_percentage" do
      expect(calculation.total_tip_outs_given_percentage).to eq(0)
    end

    it "#total_tip_outs_given_cc" do
      expect(calculation.total_tip_outs_given_cc).to eq(0)
    end

    it "#total_tip_outs_given_cash" do
      expect(calculation.total_tip_outs_given_cash).to eq(0)
    end

    it "#total_tip_outs_received_cc" do
      expect(calculation.total_tip_outs_received_cc).to eq(0)
    end

    it "#total_tip_outs_received_cash" do
      expect(calculation.total_tip_outs_received_cash).to eq(0)
    end

    it "#total_tips_distributed_cc" do
      expect(calculation.total_tips_distributed_cc).to eq(0)
    end

    it "#total_tips_distributed_cash" do
      expect(calculation.total_tips_distributed_cash).to eq(0)
    end

    it "#total_tips_distributed_global" do
      expect(calculation.total_tips_distributed_global).to eq(0)
    end
  end

  context "simple calculation with multiple employees in 1 team exist" do
    let!(:sender_calculation) { FactoryGirl.create(:calculation,
      restaurant: restaurant.reload,
      user: restaurant.user,
      shift_type: restaurant.shift_types.first,
      area_type: restaurant.area_types.last,
      source_positions: [restaurant.position_types.first]
      )
    }

    let!(:percantage_1) { calculation.percent_distributions[0] }
    let!(:percantage_2) { calculation.percent_distributions[1] }

    let!(:employee_1_from_team_1) { percantage_1.position_type.employees.first }
    let!(:employee_2_from_team_1) { percantage_1.position_type.employees.second }
    let!(:employee_3) { percantage_2.position_type.employees.first }

    let!(:area_2) { restaurant.area_types.last }

    let!(:tip_out_received) { TipOut.create(
      percentage: 50,
      cc_summ: 10,
      cash_summ: 20,
      receiver_calculation: calculation,
      sender_calculation: sender_calculation,
      date: calculation.date,
      sender: sender_calculation.area_type,
      receiver: calculation.area_type,
      shift_type: calculation.shift_type
      )
    }

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
                            "#{ employee_1_from_team_1.id }" => {
                                "hoursWorkedInHours" => "10",
                                "totalMoneyIn" => {
                                    "cc" => "100.0",
                                    "cash" => "200.0"
                                },
                                "totalMoneyOut" => {},
                                "totalTipOutsGiven" => {},
                                "totalTipOutsReceived" => {},
                                "finalMoneyToDistribute" => {}
                            },
                            "#{ employee_2_from_team_1.id }" => {
                                "hoursWorkedInHours" => "5",
                                "totalMoneyIn" => {
                                    "cc" => "50.0",
                                    "cash" => "100.0"
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
                "positionTypeIsASource" => "false",
                "teams" => {
                    "1" => {
                        "employees" => {
                            "#{ employee_3.id }" => {
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
        "tips" => {
            "given" => {
                "#{ area_2.name }" => {
                       "area_type_id" => area_2.id,
                    "percentage" => "25.00"
                }
            }
        },
        "percentage" => {
            "#{ percantage_1.id }" => "50",
            "#{ percantage_2.id }" => "50",
        },
        "id" => calculation.id
      }

      calculation.update_calculation(@params)
    end

    it "should create tip out" do
      expect(calculation.sent_tip_outs.count).to eq(1)
    end

    it "should create tip out with 25 %" do
      expect(calculation.sent_tip_outs.first.percentage).to eq(25)
    end

    it "should have 3 employee distributions" do
      expect(calculation.employee_distributions.count).to eq(3)
    end

    it "should have right input money numbers in employee distributions for source type" do
      ed_1 = calculation.employee_distributions.where(position_type: calculation.source_positions.first).first

      expect(ed_1.cc_tips).to eq(100)
      expect(ed_1.cash_tips).to eq(200)

      ed_2 = calculation.employee_distributions.where(position_type: calculation.source_positions.first).second

      expect(ed_2.cc_tips).to eq(50)
      expect(ed_2.cash_tips).to eq(100)
    end

    it "should have right numbers for 1 employee distribution" do
      ed_1 = calculation.employee_distributions.find_by(employee: employee_1_from_team_1)

      expect(ed_1.cc_tips_distr).to eq(50)
      expect(ed_1.cash_tips_distr).to eq(100)
      expect(ed_1.tip_outs_given_cc).to eq(12.5)
      expect(ed_1.tip_outs_given_cash).to eq(25)
      expect(ed_1.tip_outs_received_cc.round(2)).to eq(3.33)
      expect(ed_1.tip_outs_received_cash.round(2)).to eq(6.67)

      expect(ed_1.cc_tips_distr_final.round(2)).to eq(40.83)
      expect(ed_1.cash_tips_distr_final.round(2)).to eq(81.67)
    end

    it "should have right numbers for 2 employee distribution" do
      ed_2 = calculation.employee_distributions.find_by(employee: employee_2_from_team_1)
      ed_2 = calculation.employee_distributions[1]

      expect(ed_2.cc_tips_distr).to eq(25)
      expect(ed_2.cash_tips_distr).to eq(50)
      expect(ed_2.tip_outs_given_cc).to eq(6.25)
      expect(ed_2.tip_outs_given_cash).to eq(12.5)
      expect(ed_2.tip_outs_received_cc.round(2)).to eq(1.67)
      expect(ed_2.tip_outs_received_cash.round(2)).to eq(3.33)

      expect(ed_2.cc_tips_distr_final.round(2)).to eq(20.42)
      expect(ed_2.cash_tips_distr_final.round(2)).to eq(40.83)
    end

    it "should have right numbers for 3 employee distribution" do
      ed_3 = calculation.employee_distributions[2]

      expect(ed_3.cc_tips_distr).to eq(75)
      expect(ed_3.cash_tips_distr).to eq(150)
      expect(ed_3.cc_tips_distr_final).to eq(61.25)
      expect(ed_3.cash_tips_distr_final).to eq(122.5)
      expect(ed_3.tip_outs_given_cc).to eq(18.75)
      expect(ed_3.tip_outs_given_cash).to eq(37.5)
      expect(ed_3.tip_outs_received_cc).to eq(5)
      expect(ed_3.tip_outs_received_cash).to eq(10)
    end

    it "#total_tip_outs_given_percentage" do
      expect(calculation.total_tip_outs_given_percentage).to eq(25)
    end

    it "#total_tip_outs_given_cc" do
      expect(calculation.total_tip_outs_given_cc).to eq(37.5)
    end

    it "#total_tip_outs_given_cash" do
      expect(calculation.total_tip_outs_given_cash).to eq(75)
    end

    it "#total_tip_outs_received_cc" do
      expect(calculation.total_tip_outs_received_cc).to eq(10)
    end

    it "#total_tip_outs_received_cash" do
      expect(calculation.total_tip_outs_received_cash).to eq(20)
    end

    it "#total_tips_distributed_cc" do
      expect(calculation.total_tips_distributed_cc).to eq(122.5)
    end

    it "#total_tips_distributed_cash" do
      expect(calculation.total_tips_distributed_cash).to eq(245)
    end

    it "#total_tips_distributed_global" do
      expect(calculation.total_tips_distributed_global).to eq(367.5)
    end
  end

  # TODO:
  xit "should have 4 used position types when source type is new for this calc" do
    expect(calculation.used_position_types.count).to eq(3)
  end
  xit "calculation with multiple teams"
  xit "calculation with multiple employees in 1 team"
  xit "calculation by POINTS without tipouts exist"
  xit "calculation by POINTS with tipouts exist"
  xit "#create_day_calculation"
  xit "#create_day_area_calculation"
  xit "#related_employees"
  xit "Calculation#build_by"
  xit "#create_percent_distributions"
  xit "#total_cc_tips"
  xit "#total_cash_tips"
  xit "#total_collected_tips"
  xit "#is_blank?"
  xit "#recalculate"
  xit "#report_by"
  context "Tip Outs logic"
  context "Sumit logic" do
    xit "#pending_distributions"
  end
  context "Duplicated logic" do
    xit "#duplicate"
  end
end
