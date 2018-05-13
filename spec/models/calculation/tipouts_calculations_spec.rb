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

  context "simple calculation witр given tip outs exist" do

    let!(:percantage_1) { calculation.percent_distributions[0] }
    let!(:percantage_2) { calculation.percent_distributions[1] }
    let!(:percantage_3) { calculation.percent_distributions[2] }

    let!(:employee_1) { percantage_1.position_type.employees.first }
    let!(:employee_2) { percantage_2.position_type.employees.first }
    let!(:employee_3) { percantage_3.position_type.employees.first }

    let!(:area_2) { restaurant.area_types.last }

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
        "tips" => {
            "given" => {
                "#{ area_2.name }" => {
                       "area_type_id" => area_2.id,
                    "percentage" => "25.00"
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
      ed = calculation.employee_distributions.where(position_type: calculation.source_positions.first).first

      expect(ed.cc_tips).to eq(100)
      expect(ed.cash_tips).to eq(200)
    end

    it "should have right numbers for 1 employee distribution" do
      ed_1 = calculation.employee_distributions[0]

      expect(ed_1.cc_tips_distr).to eq(30)
      expect(ed_1.cash_tips_distr).to eq(60)
      expect(ed_1.cc_tips_distr_final).to eq(22.5)
      expect(ed_1.cash_tips_distr_final).to eq(45)
      expect(ed_1.tip_outs_given_cc).to eq(7.5)
      expect(ed_1.tip_outs_given_cash).to eq(15)
      expect(ed_1.tip_outs_received_cc).to eq(0)
      expect(ed_1.tip_outs_received_cash).to eq(0)
    end

    it "should have right numbers for 2 employee distribution" do
      ed_2 = calculation.employee_distributions[1]

      expect(ed_2.cc_tips_distr).to eq(20)
      expect(ed_2.cash_tips_distr).to eq(40)
      expect(ed_2.cc_tips_distr_final).to eq(15)
      expect(ed_2.cash_tips_distr_final).to eq(30)
      expect(ed_2.tip_outs_given_cc).to eq(5)
      expect(ed_2.tip_outs_given_cash).to eq(10)
      expect(ed_2.tip_outs_received_cc).to eq(0)
      expect(ed_2.tip_outs_received_cash).to eq(0)
    end

    it "should have right numbers for 3 employee distribution" do
      ed_3 = calculation.employee_distributions[2]

      expect(ed_3.cc_tips_distr).to eq(50)
      expect(ed_3.cash_tips_distr).to eq(100)
      expect(ed_3.cc_tips_distr_final).to eq(37.5)
      expect(ed_3.cash_tips_distr_final).to eq(75)
      expect(ed_3.tip_outs_given_cc).to eq(12.5)
      expect(ed_3.tip_outs_given_cash).to eq(25)
      expect(ed_3.tip_outs_received_cc).to eq(0)
      expect(ed_3.tip_outs_received_cash).to eq(0)
    end

    it "#total_tip_outs_given_percentage" do
      expect(calculation.total_tip_outs_given_percentage).to eq(25)
    end

    it "#total_tip_outs_given_cc" do
      expect(calculation.total_tip_outs_given_cc).to eq(25)
    end

    it "#total_tip_outs_given_cash" do
      expect(calculation.total_tip_outs_given_cash).to eq(50)
    end

    it "#total_tip_outs_received_cc" do
      expect(calculation.total_tip_outs_received_cc).to eq(0)
    end

    it "#total_tip_outs_received_cash" do
      expect(calculation.total_tip_outs_received_cash).to eq(0)
    end

    it "#total_tips_distributed_cc" do
      expect(calculation.total_tips_distributed_cc).to eq(75)
    end

    it "#total_tips_distributed_cash" do
      expect(calculation.total_tips_distributed_cash).to eq(150)
    end

    it "#total_tips_distributed_global" do
      expect(calculation.total_tips_distributed_global).to eq(225)
    end
  end

  context "simple calculation with multiple given tip outs exist" do

    let!(:percantage_1) { calculation.percent_distributions[0] }
    let!(:percantage_2) { calculation.percent_distributions[1] }
    let!(:percantage_3) { calculation.percent_distributions[2] }

    let!(:employee_1) { percantage_1.position_type.employees.first }
    let!(:employee_2) { percantage_2.position_type.employees.first }
    let!(:employee_3) { percantage_3.position_type.employees.first }

    let!(:area_2) { restaurant.area_types[1] }
    let!(:area_3) { restaurant.area_types[2] }

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
        "tips" => {
            "given" => {
                "#{ area_2.name }" => {
                       "area_type_id" => area_2.id,
                    "percentage" => "25.00"
                },
                "#{ area_3.name }" => {
                       "area_type_id" => area_3.id,
                    "percentage" => "25.00"
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

    it "should create tip out" do
      expect(calculation.sent_tip_outs.count).to eq(2)
    end

    it "should create tip outs with 25 %" do
      expect(calculation.sent_tip_outs.first.percentage).to eq(25)
      expect(calculation.sent_tip_outs.second.percentage).to eq(25)
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
      expect(ed_1.cc_tips_distr_final).to eq(15)
      expect(ed_1.cash_tips_distr_final).to eq(30)
      expect(ed_1.tip_outs_given_cc).to eq(15)
      expect(ed_1.tip_outs_given_cash).to eq(30)
      expect(ed_1.tip_outs_received_cc).to eq(0)
      expect(ed_1.tip_outs_received_cash).to eq(0)
    end

    it "should have right numbers for 2 employee distribution" do
      ed_2 = calculation.employee_distributions[1]

      expect(ed_2.cc_tips_distr).to eq(20)
      expect(ed_2.cash_tips_distr).to eq(40)
      expect(ed_2.cc_tips_distr_final).to eq(10)
      expect(ed_2.cash_tips_distr_final).to eq(20)
      expect(ed_2.tip_outs_given_cc).to eq(10)
      expect(ed_2.tip_outs_given_cash).to eq(20)
      expect(ed_2.tip_outs_received_cc).to eq(0)
      expect(ed_2.tip_outs_received_cash).to eq(0)
    end

    it "should have right numbers for 3 employee distribution" do
      ed_3 = calculation.employee_distributions[2]

      expect(ed_3.cc_tips_distr).to eq(50)
      expect(ed_3.cash_tips_distr).to eq(100)
      expect(ed_3.cc_tips_distr_final).to eq(25)
      expect(ed_3.cash_tips_distr_final).to eq(50)
      expect(ed_3.tip_outs_given_cc).to eq(25)
      expect(ed_3.tip_outs_given_cash).to eq(50)
      expect(ed_3.tip_outs_received_cc).to eq(0)
      expect(ed_3.tip_outs_received_cash).to eq(0)
    end

    it "#total_tip_outs_given_percentage" do
      expect(calculation.total_tip_outs_given_percentage).to eq(50)
    end

    it "#total_tip_outs_given_cc" do
      expect(calculation.total_tip_outs_given_cc).to eq(50)
    end

    it "#total_tip_outs_given_cash" do
      expect(calculation.total_tip_outs_given_cash).to eq(100)
    end

    it "#total_tip_outs_received_cc" do
      expect(calculation.total_tip_outs_received_cc).to eq(0)
    end

    it "#total_tip_outs_received_cash" do
      expect(calculation.total_tip_outs_received_cash).to eq(0)
    end

    it "#total_tips_distributed_cc" do
      expect(calculation.total_tips_distributed_cc).to eq(50)
    end

    it "#total_tips_distributed_cash" do
      expect(calculation.total_tips_distributed_cash).to eq(100)
    end

    it "#total_tips_distributed_global" do
      expect(calculation.total_tips_distributed_global).to eq(150)
    end
  end

  context "simple calculation with tip outs received" do
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
    let!(:percantage_3) { calculation.percent_distributions[2] }

    let!(:employee_1) { percantage_1.position_type.employees.first }
    let!(:employee_2) { percantage_2.position_type.employees.first }
    let!(:employee_3) { percantage_3.position_type.employees.first }

    let!(:tip_out_received) { TipOut.create(
      percentage: 50,
      cc_summ: 50,
      cash_summ: 100,
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

    it "should not create tip out" do
      expect(calculation.sent_tip_outs.count).to eq(0)
    end

    it "should have received tip outs" do
      expect(calculation.received_tip_outs.count).to eq(1)
    end

    it "should have received tip outs with 50 CC and 100 Cash" do
      expect(calculation.received_tip_outs.first.percentage).to eq(50)
      expect(calculation.received_tip_outs.first.cc_summ).to eq(50)
      expect(calculation.received_tip_outs.first.cash_summ).to eq(100)
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
      expect(ed_1.cc_tips_distr_final).to eq(45)
      expect(ed_1.cash_tips_distr_final).to eq(90)
      expect(ed_1.tip_outs_given_cc).to eq(0)
      expect(ed_1.tip_outs_given_cash).to eq(0)
      expect(ed_1.tip_outs_received_cc).to eq(15)
      expect(ed_1.tip_outs_received_cash).to eq(30)
    end

    it "should have right numbers for 2 employee distribution" do
      ed_2 = calculation.employee_distributions[1]

      expect(ed_2.cc_tips_distr).to eq(20)
      expect(ed_2.cash_tips_distr).to eq(40)
      expect(ed_2.cc_tips_distr_final).to eq(30)
      expect(ed_2.cash_tips_distr_final).to eq(60)
      expect(ed_2.tip_outs_given_cc).to eq(0)
      expect(ed_2.tip_outs_given_cash).to eq(0)
      expect(ed_2.tip_outs_received_cc).to eq(10)
      expect(ed_2.tip_outs_received_cash).to eq(20)
    end

    it "should have right numbers for 3 employee distribution" do
      ed_3 = calculation.employee_distributions[2]

      expect(ed_3.cc_tips_distr).to eq(50)
      expect(ed_3.cash_tips_distr).to eq(100)
      expect(ed_3.cc_tips_distr_final).to eq(75)
      expect(ed_3.cash_tips_distr_final).to eq(150)
      expect(ed_3.tip_outs_given_cc).to eq(0)
      expect(ed_3.tip_outs_given_cash).to eq(0)
      expect(ed_3.tip_outs_received_cc).to eq(25)
      expect(ed_3.tip_outs_received_cash).to eq(50)
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
      expect(calculation.total_tip_outs_received_cc).to eq(50)
    end

    it "#total_tip_outs_received_cash" do
      expect(calculation.total_tip_outs_received_cash).to eq(100)
    end

    it "#total_tips_distributed_cc" do
      expect(calculation.total_tips_distributed_cc).to eq(150)
    end

    it "#total_tips_distributed_cash" do
      expect(calculation.total_tips_distributed_cash).to eq(300)
    end

    it "#total_tips_distributed_global" do
      expect(calculation.total_tips_distributed_global).to eq(450)
    end
  end

  context "calculation with both given and received tip outs" do
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
    let!(:percantage_3) { calculation.percent_distributions[2] }

    let!(:employee_1) { percantage_1.position_type.employees.first }
    let!(:employee_2) { percantage_2.position_type.employees.first }
    let!(:employee_3) { percantage_3.position_type.employees.first }

    let!(:area_2) { restaurant.area_types[1] }
    let!(:area_1) { restaurant.area_types[0] }

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
        "tips" => {
            "given" => {
                "#{ area_2.name }" => {
                       "area_type_id" => area_2.id,
                    "percentage" => "25.00"
                },
                "#{ area_1.name }" => {
                       "area_type_id" => area_1.id,
                    "percentage" => "25.00"
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

    it "should not create tip out" do
      expect(calculation.sent_tip_outs.count).to eq(2)
    end

    it "should have received tip outs" do
      expect(calculation.received_tip_outs.count).to eq(1)
    end

    it "should have received tip outs with 50 CC and 100 Cash" do
      expect(calculation.received_tip_outs.first.percentage).to eq(50)
      expect(calculation.received_tip_outs.first.cc_summ).to eq(60)
      expect(calculation.received_tip_outs.first.cash_summ).to eq(120)
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
      expect(ed_1.cc_tips_distr_final).to eq(33)
      expect(ed_1.cash_tips_distr_final).to eq(66)
      expect(ed_1.tip_outs_given_cc).to eq(15)
      expect(ed_1.tip_outs_given_cash).to eq(30)
      expect(ed_1.tip_outs_received_cc).to eq(18)
      expect(ed_1.tip_outs_received_cash).to eq(36)
    end

    it "should have right numbers for 2 employee distribution" do
      ed_2 = calculation.employee_distributions[1]

      expect(ed_2.cc_tips_distr).to eq(20)
      expect(ed_2.cash_tips_distr).to eq(40)
      expect(ed_2.cc_tips_distr_final).to eq(22)
      expect(ed_2.cash_tips_distr_final).to eq(44)
      expect(ed_2.tip_outs_given_cc).to eq(10)
      expect(ed_2.tip_outs_given_cash).to eq(20)
      expect(ed_2.tip_outs_received_cc).to eq(12)
      expect(ed_2.tip_outs_received_cash).to eq(24)
    end

    it "should have right numbers for 3 employee distribution" do
      ed_3 = calculation.employee_distributions[2]

      expect(ed_3.cc_tips_distr).to eq(50)
      expect(ed_3.cash_tips_distr).to eq(100)
      expect(ed_3.cc_tips_distr_final).to eq(55)
      expect(ed_3.cash_tips_distr_final).to eq(110)
      expect(ed_3.tip_outs_given_cc).to eq(25)
      expect(ed_3.tip_outs_given_cash).to eq(50)
      expect(ed_3.tip_outs_received_cc).to eq(30)
      expect(ed_3.tip_outs_received_cash).to eq(60)
    end

    it "#total_tip_outs_given_percentage" do
      expect(calculation.total_tip_outs_given_percentage).to eq(50)
    end

    it "#total_tip_outs_given_cc" do
      expect(calculation.total_tip_outs_given_cc).to eq(50)
    end

    it "#total_tip_outs_given_cash" do
      expect(calculation.total_tip_outs_given_cash).to eq(100)
    end

    it "#total_tip_outs_received_cc" do
      expect(calculation.total_tip_outs_received_cc).to eq(60)
    end

    it "#total_tip_outs_received_cash" do
      expect(calculation.total_tip_outs_received_cash).to eq(120)
    end

    it "#total_tips_distributed_cc" do
      expect(calculation.total_tips_distributed_cc).to eq(110)
    end

    it "#total_tips_distributed_cash" do
      expect(calculation.total_tips_distributed_cash).to eq(220)
    end

    it "#total_tips_distributed_global" do
      expect(calculation.total_tips_distributed_global).to eq(330)
    end
  end
end
