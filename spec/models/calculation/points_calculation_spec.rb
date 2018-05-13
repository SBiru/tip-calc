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

  context "simple points calculation with given tip outs exist" do

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

      calculation.source_positions = [percantage_1.position_type]
      calculation.save

      @params = {
        "calculationId" => calculation.id,
        "distribution_type" => "points",
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
                                    "cc" => "161.88",
                                    "cash" => "71.0"
                                },
                                "totalMoneyOut" => {},
                                "totalTipOutsGiven" => {},
                                "totalTipOutsReceived" => {},
                                "finalMoneyToDistribute" => {}
                            },
                            "#{ employee_1_2.id }" => {
                                "hoursWorkedInHours" => "1",
                                "totalMoneyIn" => {
                                    "cc" => "334.83",
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
                            "#{ employee_2_1.id }" => {
                                "hoursWorkedInHours" => "2",
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
                            },
                            "#{ employee_3_2.id }" => {
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
                    "percentage" => "5.00"
                }
            }
        },
        "percentage" => {
            "#{ percantage_1.id }" => "8",
            "#{ percantage_2.id }" => "2.5",
            "#{ percantage_3.id }" => "4",
        },
        "id" => calculation.id
      }

      calculation.update_calculation(@params)
    end

    it "should calculate total points" do
      expect(calculation.get_total_calculation_points).to eq(29)
    end

    it "should create tip out" do
      expect(calculation.sent_tip_outs.count).to eq(1)
    end

    it "should create tip out with 5 %" do
      expect(calculation.sent_tip_outs.first.percentage).to eq(5)
    end

    it "should have 5 employee distributions" do
      expect(calculation.employee_distributions.count).to eq(5)
    end

    it "should have right input money numbers in employee distributions for source type" do
      ed_1 = calculation.employee_distributions.where(employee: employee_1_1).first

      expect(ed_1.cc_tips.round(2)).to eq(161.88)
      expect(ed_1.cash_tips.round(2)).to eq(71)

      ed_2 = calculation.employee_distributions.where(employee: employee_1_2).first

      expect(ed_2.cc_tips.round(2)).to eq(334.83)
      expect(ed_2.cash_tips.round(2)).to eq(0)
    end

    it "should have right numbers for 1.1 employee distribution" do
      ed_1 = calculation.employee_distributions.where(employee: employee_1_1).first

      expect(ed_1.cc_tips_distr.round(2)).to eq(137.02)
      expect(ed_1.cash_tips_distr.round(2)).to eq(19.59)
      expect(ed_1.cc_tips_distr_final.round(2)).to eq(130.17)
      expect(ed_1.cash_tips_distr_final.round(2)).to eq(18.61)
      expect(ed_1.tip_outs_given_cc.round(2)).to eq(6.85)
      expect(ed_1.tip_outs_given_cash.round(2)).to eq(0.98)
      expect(ed_1.tip_outs_received_cc.round(2)).to eq(0)
      expect(ed_1.tip_outs_received_cash.round(2)).to eq(0)
    end

    it "should have right numbers for 1.2 employee distribution" do
      ed_2 = calculation.employee_distributions.where(employee: employee_1_2).first

      expect(ed_2.cc_tips_distr.round(2)).to eq(137.02)
      expect(ed_2.cash_tips_distr.round(2)).to eq(19.59)
      expect(ed_2.cc_tips_distr_final.round(2)).to eq(130.17)
      expect(ed_2.cash_tips_distr_final.round(2)).to eq(18.61)
      expect(ed_2.tip_outs_given_cc.round(2)).to eq(6.85)
      expect(ed_2.tip_outs_given_cash.round(2)).to eq(0.98)
      expect(ed_2.tip_outs_received_cc.round(2)).to eq(0)
      expect(ed_2.tip_outs_received_cash.round(2)).to eq(0)
    end

    it "should have right numbers for 2.1 employee distribution" do
      ed_3 = calculation.employee_distributions.where(employee: employee_2_1).first

      expect(ed_3.cc_tips_distr.round(2)).to eq(85.64)
      expect(ed_3.cash_tips_distr.round(2)).to eq(12.24)
      expect(ed_3.cc_tips_distr_final.round(2)).to eq(81.36)
      expect(ed_3.cash_tips_distr_final.round(2)).to eq(11.63)
      expect(ed_3.tip_outs_given_cc.round(2)).to eq(4.28)
      expect(ed_3.tip_outs_given_cash.round(2)).to eq(0.61)
      expect(ed_3.tip_outs_received_cc.round(2)).to eq(0)
      expect(ed_3.tip_outs_received_cash.round(2)).to eq(0)
    end

    it "should have right numbers for 3.1 employee distribution" do
      ed_4 = calculation.employee_distributions.where(employee: employee_3_1).first

      expect(ed_4.cc_tips_distr.round(2)).to eq(68.51)
      expect(ed_4.cash_tips_distr.round(2)).to eq(9.79)
      expect(ed_4.cc_tips_distr_final.round(2)).to eq(65.09)
      expect(ed_4.cash_tips_distr_final.round(2)).to eq(9.30)
      expect(ed_4.tip_outs_given_cc.round(2)).to eq(3.43)
      expect(ed_4.tip_outs_given_cash.round(2)).to eq(0.49)
      expect(ed_4.tip_outs_received_cc.round(2)).to eq(0)
      expect(ed_4.tip_outs_received_cash.round(2)).to eq(0)
    end

    it "should have right numbers for 3.2 employee distribution" do
      ed_5 = calculation.employee_distributions.where(employee: employee_3_2).first

      expect(ed_5.cc_tips_distr.round(2)).to eq(68.51)
      expect(ed_5.cash_tips_distr.round(2)).to eq(9.79)
      expect(ed_5.cc_tips_distr_final.round(2)).to eq(65.09)
      expect(ed_5.cash_tips_distr_final.round(2)).to eq(9.30)
      expect(ed_5.tip_outs_given_cc.round(2)).to eq(3.43)
      expect(ed_5.tip_outs_given_cash.round(2)).to eq(0.49)
      expect(ed_5.tip_outs_received_cc.round(2)).to eq(0)
      expect(ed_5.tip_outs_received_cash.round(2)).to eq(0)
    end

    it "#total_tip_outs_given_percentage" do
      expect(calculation.total_tip_outs_given_percentage).to eq(5)
    end

    it "#total_tip_outs_given_cc" do
      expect(calculation.total_tip_outs_given_cc.round(2)).to eq(24.84)
    end

    it "#total_tip_outs_given_cash" do
      expect(calculation.total_tip_outs_given_cash.round(2)).to eq(3.55)
    end

    it "#total_tip_outs_received_cc" do
      expect(calculation.total_tip_outs_received_cc.round(2)).to eq(0)
    end

    it "#total_tip_outs_received_cash" do
      expect(calculation.total_tip_outs_received_cash.round(2)).to eq(0)
    end

    it "#total_tips_distributed_cc" do
      expect(calculation.total_tips_distributed_cc.round(2)).to eq(471.87)
    end

    it "#total_tips_distributed_cash" do
      expect(calculation.total_tips_distributed_cash.round(2)).to eq(67.45)
    end

    it "#total_tips_distributed_global" do
      expect(calculation.total_tips_distributed_global.round(2)).to eq(539.32)
    end
  end

  # context "simple points calculation with given tip outs exist" do
  #   let!(:percantage_1) { calculation.percent_distributions[0] }
  #   let!(:percantage_2) { calculation.percent_distributions[1] }
  #   let!(:percantage_3) { calculation.percent_distributions[2] }

  #   let!(:employee_1_1) { percantage_1.position_type.employees.first }
  #   let!(:employee_1_2) { percantage_1.position_type.employees.second }
  #   let!(:employee_2_1) { percantage_2.position_type.employees.first }
  #   let!(:employee_3_1) { percantage_3.position_type.employees.first }
  #   let!(:employee_3_2) { percantage_3.position_type.employees.second }

  #   let!(:area_2) { restaurant.area_types.last }

  #   before :each do

  #     calculation.source_positions = [percantage_1.position_type]
  #     calculation.save

  #     @params = {
  #       "calculationId" => calculation.id,
  #       "distribution_type" => "points",
  #       "posTotals" => {
  #           "calculationPosTotal" => "0",
  #           "dayPosTotal" => "0"
  #       },

  #       "positionsMoney" => {
  #           "#{ percantage_1.position_type.name }" => {
  #               "positionTypeIsASource" => "true",
  #               "teams" => {
  #                   "1" => {
  #                       "employees" => {
  #                           "#{ employee_1_1.id }" => {
  #                               "hoursWorkedInHours" => "1",
  #                               "totalMoneyIn" => {
  #                                   "cc" => "161.88",
  #                                   "cash" => "71.0"
  #                               }
  #                           },
  #                           "#{ employee_1_2.id }" => {
  #                               "hoursWorkedInHours" => "1",
  #                               "totalMoneyIn" => {
  #                                   "cc" => "334.83",
  #                                   "cash" => "0.0"
  #                               }
  #                           }
  #                       }
  #                   }
  #               }
  #           },
  #           "#{ percantage_2.position_type.name }" => {
  #               "positionTypeIsASource" => "false",
  #               "teams" => {
  #                   "1" => {
  #                       "employees" => {
  #                           "#{ employee_2_1.id }" => {
  #                               "hoursWorkedInHours" => "2"
  #                           }
  #                       }
  #                   }
  #               }
  #           },
  #           "#{ percantage_3.position_type.name }" => {
  #               "positionTypeIsASource" => "false",
  #               "teams" => {
  #                   "1" => {
  #                       "employees" => {
  #                           "#{ employee_3_1.id }" => {
  #                               "hoursWorkedInHours" => "1"
  #                           },
  #                           "#{ employee_3_2.id }" => {
  #                               "hoursWorkedInHours" => "1"
  #                           }
  #                       }
  #                   }
  #               }
  #           }
  #       },
  #       "tips" => {
  #           "given" => {
  #               "#{ area_2.name }" => {
  #                      "area_id" => area_2.id,
  #                   "percentage" => "5.00"
  #               }
  #           }
  #       },
  #       "percentage" => {
  #           "#{ percantage_1.id }" => "8",
  #           "#{ percantage_2.id }" => "2.5",
  #           "#{ percantage_3.id }" => "4",
  #       },
  #       "id" => calculation.id
  #     }

  #     calculation.update_calculation(@params)
  #   end

  #   context "updating existing calculation without tip outs but x10 summ" do
  #     before :each do
  #       calculation.source_positions = [percantage_1.position_type]
  #       calculation.save
  #       calculation.reload

  #       @params = {
  #         "calculationId" => calculation.id,
  #         "distribution_type" => "points",
  #         "posTotals" => {
  #             "calculationPosTotal" => "0",
  #             "dayPosTotal" => "0"
  #         },
  #         "positionsMoney" => {
  #             "#{ percantage_1.position_type.name }" => {
  #                 "positionTypeIsASource" => "true",
  #                 "teams" => {
  #                     "1" => {
  #                         "employees" => {
  #                             "#{ employee_1_1.id }" => {
  #                                 "hoursWorkedInHours" => "1",
  #                                 "distributionStatus" => "persisted",
  #                                 "distributionId" => calculation.employee_distributions.where(employee: employee_1_1).first.id,
  #                                 "totalMoneyIn" => {
  #                                     "cc" => "1618.8",
  #                                     "cash" => "710"
  #                                 }
  #                             },
  #                             "#{ employee_1_2.id }" => {
  #                                 "hoursWorkedInHours" => "1",
  #                                 "distributionStatus" => "persisted",
  #                                 "distributionId" => calculation.employee_distributions.where(employee: employee_1_2).first.id,
  #                                 "totalMoneyIn" => {
  #                                     "cc" => "3348.3",
  #                                     "cash" => "0.0"
  #                                 }
  #                             }
  #                         }
  #                     }
  #                 }
  #             },
  #             "#{ percantage_2.position_type.name }" => {
  #                 "positionTypeIsASource" => "false",
  #                 "teams" => {
  #                     "1" => {
  #                         "employees" => {
  #                             "#{ employee_2_1.id }" => {
  #                                 "hoursWorkedInHours" => "2",
  #                                 "distributionStatus" => "persisted",
  #                                 "distributionId" => calculation.employee_distributions.where(employee: employee_2_1).first.id,
  #                             }
  #                         }
  #                     }
  #                 }
  #             },
  #             "#{ percantage_3.position_type.name }" => {
  #                 "positionTypeIsASource" => "false",
  #                 "teams" => {
  #                     "1" => {
  #                         "employees" => {
  #                             "#{ employee_3_1.id }" => {
  #                                 "hoursWorkedInHours" => "1",
  #                                 "distributionStatus" => "persisted",
  #                                 "distributionId" => calculation.employee_distributions.where(employee: employee_3_1).first.id,
  #                             },
  #                             "#{ employee_3_2.id }" => {
  #                                 "hoursWorkedInHours" => "1",
  #                                 "distributionStatus" => "persisted",
  #                                 "distributionId" => calculation.employee_distributions.where(employee: employee_3_2).first.id,
  #                             }
  #                         }
  #                     }
  #                 }
  #             }
  #         },
  #         "tips" => {
  #             "given" => {
  #                 "#{ area_2.name }" => {
  #                        "area_id" => area_2.id,
  #                     "percentage" => "0"
  #                 }
  #             }
  #         },
  #         "percentage" => {
  #             "#{ percantage_1.id }" => "8",
  #             "#{ percantage_2.id }" => "2.5",
  #             "#{ percantage_3.id }" => "4",
  #         },
  #         "id" => calculation.id
  #       }

  #       calculation.update_calculation(@params)
  #       calculation.reload
  #     end

  #     it "should calculate total points" do
  #       expect(calculation.get_total_calculation_points).to eq(29)
  #     end

  #     it "should create tip out" do
  #       expect(calculation.sent_tip_outs.count).to eq(1)
  #     end

  #     it "should create tip out with 5 %" do
  #       expect(calculation.sent_tip_outs.first.percentage).to eq(0)
  #     end

  #     it "should have 5 employee distributions" do
  #       expect(calculation.employee_distributions.count).to eq(5)
  #     end

  #     it "should have right input money numbers in employee distributions for source type" do
  #       ed_1 = calculation.employee_distributions.where(employee: employee_1_1).first

  #       expect(ed_1.cc_tips.round(2)).to eq(1618.8)
  #       expect(ed_1.cash_tips.round(2)).to eq(710)

  #       ed_2 = calculation.employee_distributions.where(employee: employee_1_2).first

  #       expect(ed_2.cc_tips.round(2)).to eq(3348.3)
  #       expect(ed_2.cash_tips.round(2)).to eq(0)
  #     end

  #     it "should have right numbers for 1.1 employee distribution" do
  #       ed_1 = calculation.employee_distributions.where(employee: employee_1_1).first

  #       expect(ed_1.cc_tips_distr.round(1)).to eq(1370.2)
  #       expect(ed_1.cash_tips_distr.round(1)).to eq(195.9)
  #       expect(ed_1.cc_tips_distr_final.round(1)).to eq(1370.2)
  #       expect(ed_1.cash_tips_distr_final.round(1)).to eq(195.9)
  #       expect(ed_1.tip_outs_given_cc.round(1)).to eq(0)
  #       expect(ed_1.tip_outs_given_cash.round(1)).to eq(0)
  #       expect(ed_1.tip_outs_received_cc.round(1)).to eq(0)
  #       expect(ed_1.tip_outs_received_cash.round(1)).to eq(0)
  #     end

  #     it "should have right numbers for 1.2 employee distribution" do
  #       ed_2 = calculation.employee_distributions.where(employee: employee_1_2).first

  #       expect(ed_2.cc_tips_distr.round(1)).to eq(1370.2)
  #       expect(ed_2.cash_tips_distr.round(1)).to eq(195.9)
  #       expect(ed_2.cc_tips_distr_final.round(1)).to eq(1370.2)
  #       expect(ed_2.cash_tips_distr_final.round(1)).to eq(195.9)
  #       expect(ed_2.tip_outs_given_cc.round(1)).to eq(68.5)
  #       expect(ed_2.tip_outs_given_cash.round(1)).to eq(9.8)
  #       expect(ed_2.tip_outs_received_cc.round(1)).to eq(0)
  #       expect(ed_2.tip_outs_received_cash.round(1)).to eq(0)
  #     end

  #     it "should have right numbers for 2.1 employee distribution" do
  #       ed_3 = calculation.employee_distributions.where(employee: employee_2_1).first

  #       expect(ed_3.cc_tips_distr.round(1)).to eq(856.4)
  #       expect(ed_3.cash_tips_distr.round(1)).to eq(122.4)
  #       expect(ed_3.cc_tips_distr_final.round(1)).to eq(856.4)
  #       expect(ed_3.cash_tips_distr_final.round(1)).to eq(122.4)
  #       expect(ed_3.tip_outs_given_cc.round(1)).to eq(0)
  #       expect(ed_3.tip_outs_given_cash.round(1)).to eq(0)
  #       expect(ed_3.tip_outs_received_cc.round(1)).to eq(0)
  #       expect(ed_3.tip_outs_received_cash.round(1)).to eq(0)
  #     end

  #     it "should have right numbers for 3.1 employee distribution" do
  #       ed_4 = calculation.employee_distributions.where(employee: employee_3_1).first

  #       expect(ed_4.cc_tips_distr.round(1)).to eq(685.1)
  #       expect(ed_4.cash_tips_distr.round(1)).to eq(97.9)
  #       expect(ed_4.cc_tips_distr_final.round(1)).to eq(685.1)
  #       expect(ed_4.cash_tips_distr_final.round(1)).to eq(97.9)
  #       expect(ed_4.tip_outs_given_cc.round(1)).to eq(0)
  #       expect(ed_4.tip_outs_given_cash.round(1)).to eq(0)
  #       expect(ed_4.tip_outs_received_cc.round(1)).to eq(0)
  #       expect(ed_4.tip_outs_received_cash.round(1)).to eq(0)
  #     end

  #     it "should have right numbers for 3.2 employee distribution" do
  #       ed_5 = calculation.employee_distributions.where(employee: employee_3_2).first

  #       expect(ed_5.cc_tips_distr.round(1)).to eq(685.1)
  #       expect(ed_5.cash_tips_distr.round(1)).to eq(97.9)
  #       expect(ed_5.cc_tips_distr_final.round(1)).to eq(685.1)
  #       expect(ed_5.cash_tips_distr_final.round(1)).to eq(97.9)
  #       expect(ed_5.tip_outs_given_cc.round(1)).to eq(0)
  #       expect(ed_5.tip_outs_given_cash.round(1)).to eq(0)
  #       expect(ed_5.tip_outs_received_cc.round(1)).to eq(0)
  #       expect(ed_5.tip_outs_received_cash.round(1)).to eq(0)
  #     end

  #     it "#total_tip_outs_given_percentage" do
  #       expect(calculation.total_tip_outs_given_percentage).to eq(0)
  #     end

  #     it "#total_tip_outs_given_cc" do
  #       expect(calculation.total_tip_outs_given_cc.round(2)).to eq(0)
  #     end

  #     it "#total_tip_outs_given_cash" do
  #       expect(calculation.total_tip_outs_given_cash.round(2)).to eq(0)
  #     end

  #     it "#total_tip_outs_received_cc" do
  #       expect(calculation.total_tip_outs_received_cc.round(2)).to eq(0)
  #     end

  #     it "#total_tip_outs_received_cash" do
  #       expect(calculation.total_tip_outs_received_cash.round(2)).to eq(0)
  #     end

  #     it "#total_tips_distributed_cc" do
  #       expect(calculation.total_tips_distributed_cc.round(1)).to eq(4967.1)
  #     end

  #     it "#total_tips_distributed_cash" do
  #       expect(calculation.total_tips_distributed_cash.round(1)).to eq(710)
  #     end

  #     it "#total_tips_distributed_global" do
  #       expect(calculation.total_tips_distributed_global.round(1)).to eq(5677.1)
  #     end
  #   end
  # end

  # context "simple points calculation with given tip outs exist but x10 summ" do
  #   let!(:percantage_1) { calculation.percent_distributions[0] }
  #   let!(:percantage_2) { calculation.percent_distributions[1] }
  #   let!(:percantage_3) { calculation.percent_distributions[2] }

  #   let!(:employee_1_1) { percantage_1.position_type.employees.first }
  #   let!(:employee_1_2) { percantage_1.position_type.employees.second }
  #   let!(:employee_2_1) { percantage_2.position_type.employees.first }
  #   let!(:employee_3_1) { percantage_3.position_type.employees.first }
  #   let!(:employee_3_2) { percantage_3.position_type.employees.second }

  #   let!(:area_2) { restaurant.area_types.last }

  #   before :each do

  #     calculation.source_positions = [percantage_1.position_type]
  #     calculation.save

  #     @params = {
  #       "calculationId" => calculation.id,
  #       "distribution_type" => "points",
  #       "posTotals" => {
  #           "calculationPosTotal" => "0",
  #           "dayPosTotal" => "0"
  #       },

  #       "positionsMoney" => {
  #           "#{ percantage_1.position_type.name }" => {
  #               "positionTypeIsASource" => "true",
  #               "teams" => {
  #                   "1" => {
  #                       "employees" => {
  #                           "#{ employee_1_1.id }" => {
  #                               "hoursWorkedInHours" => "1",
  #                               "totalMoneyIn" => {
  #                                   "cc" => "161.88",
  #                                   "cash" => "71.0"
  #                               }
  #                           },
  #                           "#{ employee_1_2.id }" => {
  #                               "hoursWorkedInHours" => "1",
  #                               "totalMoneyIn" => {
  #                                   "cc" => "334.83",
  #                                   "cash" => "0.0"
  #                               }
  #                           }
  #                       }
  #                   }
  #               }
  #           },
  #           "#{ percantage_2.position_type.name }" => {
  #               "positionTypeIsASource" => "false",
  #               "teams" => {
  #                   "1" => {
  #                       "employees" => {
  #                           "#{ employee_2_1.id }" => {
  #                               "hoursWorkedInHours" => "2"
  #                           }
  #                       }
  #                   }
  #               }
  #           },
  #           "#{ percantage_3.position_type.name }" => {
  #               "positionTypeIsASource" => "false",
  #               "teams" => {
  #                   "1" => {
  #                       "employees" => {
  #                           "#{ employee_3_1.id }" => {
  #                               "hoursWorkedInHours" => "1"
  #                           },
  #                           "#{ employee_3_2.id }" => {
  #                               "hoursWorkedInHours" => "1"
  #                           }
  #                       }
  #                   }
  #               }
  #           }
  #       },
  #       "tips" => {
  #           "given" => {
  #               "#{ area_2.name }" => {
  #                      "area_id" => area_2.id,
  #                   "percentage" => "5.00"
  #               }
  #           }
  #       },
  #       "percentage" => {
  #           "#{ percantage_1.id }" => "8",
  #           "#{ percantage_2.id }" => "2.5",
  #           "#{ percantage_3.id }" => "4",
  #       },
  #       "id" => calculation.id
  #     }

  #     calculation.update_calculation(@params)
  #   end

  #   context "updating existing calculation" do
  #     before :each do
  #       calculation.source_positions = [percantage_1.position_type]
  #       calculation.save
  #       calculation.reload

  #       @params = {
  #         "calculationId" => calculation.id,
  #         "distribution_type" => "points",
  #         "posTotals" => {
  #             "calculationPosTotal" => "0",
  #             "dayPosTotal" => "0"
  #         },
  #         "positionsMoney" => {
  #             "#{ percantage_1.position_type.name }" => {
  #                 "positionTypeIsASource" => "true",
  #                 "teams" => {
  #                     "1" => {
  #                         "employees" => {
  #                             "#{ employee_1_1.id }" => {
  #                                 "hoursWorkedInHours" => "1",
  #                                 "distributionStatus" => "persisted",
  #                                 "distributionId" => calculation.employee_distributions.where(employee: employee_1_1).first.id,
  #                                 "totalMoneyIn" => {
  #                                     "cc" => "1618.8",
  #                                     "cash" => "710"
  #                                 }
  #                             },
  #                             "#{ employee_1_2.id }" => {
  #                                 "hoursWorkedInHours" => "1",
  #                                 "distributionStatus" => "persisted",
  #                                 "distributionId" => calculation.employee_distributions.where(employee: employee_1_2).first.id,
  #                                 "totalMoneyIn" => {
  #                                     "cc" => "3348.3",
  #                                     "cash" => "0.0"
  #                                 }
  #                             }
  #                         }
  #                     }
  #                 }
  #             },
  #             "#{ percantage_2.position_type.name }" => {
  #                 "positionTypeIsASource" => "false",
  #                 "teams" => {
  #                     "1" => {
  #                         "employees" => {
  #                             "#{ employee_2_1.id }" => {
  #                                 "hoursWorkedInHours" => "2",
  #                                 "distributionStatus" => "persisted",
  #                                 "distributionId" => calculation.employee_distributions.where(employee: employee_2_1).first.id,
  #                             }
  #                         }
  #                     }
  #                 }
  #             },
  #             "#{ percantage_3.position_type.name }" => {
  #                 "positionTypeIsASource" => "false",
  #                 "teams" => {
  #                     "1" => {
  #                         "employees" => {
  #                             "#{ employee_3_1.id }" => {
  #                                 "hoursWorkedInHours" => "1",
  #                                 "distributionStatus" => "persisted",
  #                                 "distributionId" => calculation.employee_distributions.where(employee: employee_3_1).first.id,
  #                             },
  #                             "#{ employee_3_2.id }" => {
  #                                 "hoursWorkedInHours" => "1",
  #                                 "distributionStatus" => "persisted",
  #                                 "distributionId" => calculation.employee_distributions.where(employee: employee_3_2).first.id,
  #                             }
  #                         }
  #                     }
  #                 }
  #             }
  #         },
  #         "tips" => {
  #             "given" => {
  #                 "#{ area_2.name }" => {
  #                        "area_id" => area_2.id,
  #                     "percentage" => "5"
  #                 }
  #             }
  #         },
  #         "percentage" => {
  #             "#{ percantage_1.id }" => "8",
  #             "#{ percantage_2.id }" => "2.5",
  #             "#{ percantage_3.id }" => "4",
  #         },
  #         "id" => calculation.id
  #       }

  #       calculation.update_calculation(@params)
  #       calculation.reload
  #     end

  #     it "should calculate total points" do

  #       expect(calculation.get_total_calculation_points).to eq(29)
  #     end

  #     it "should create tip out" do
  #       expect(calculation.sent_tip_outs.count).to eq(1)
  #     end

  #     it "should create tip out with 5 %" do
  #       expect(calculation.sent_tip_outs.first.percentage).to eq(5)
  #     end

  #     it "should have 5 employee distributions" do
  #       expect(calculation.employee_distributions.count).to eq(5)
  #     end

  #     it "should have right input money numbers in employee distributions for source type" do
  #       ed_1 = calculation.employee_distributions.where(employee: employee_1_1).first

  #       expect(ed_1.cc_tips.round(2)).to eq(1618.8)
  #       expect(ed_1.cash_tips.round(2)).to eq(710)

  #       ed_2 = calculation.employee_distributions.where(employee: employee_1_2).first

  #       expect(ed_2.cc_tips.round(2)).to eq(3348.3)
  #       expect(ed_2.cash_tips.round(2)).to eq(0)
  #     end

  #     it "should have right numbers for 1.1 employee distribution" do
  #       ed_1 = calculation.employee_distributions.where(employee: employee_1_1).first

  #       expect(ed_1.cc_tips_distr.round(1)).to eq(1370.2)
  #       expect(ed_1.cash_tips_distr.round(1)).to eq(195.9)
  #       expect(ed_1.cc_tips_distr_final.round(1)).to eq(1301.7)
  #       expect(ed_1.cash_tips_distr_final.round(1)).to eq(186.1)
  #       expect(ed_1.tip_outs_given_cc.round(1)).to eq(68.5)
  #       expect(ed_1.tip_outs_given_cash.round(1)).to eq(9.8)
  #       expect(ed_1.tip_outs_received_cc.round(1)).to eq(0)
  #       expect(ed_1.tip_outs_received_cash.round(1)).to eq(0)
  #     end

  #     it "should have right numbers for 1.2 employee distribution" do
  #       ed_2 = calculation.employee_distributions.where(employee: employee_1_2).first

  #       expect(ed_2.cc_tips_distr.round(1)).to eq(1370.2)
  #       expect(ed_2.cash_tips_distr.round(1)).to eq(195.9)
  #       expect(ed_2.cc_tips_distr_final.round(1)).to eq(1301.7)
  #       expect(ed_2.cash_tips_distr_final.round(1)).to eq(186.1)
  #       expect(ed_2.tip_outs_given_cc.round(1)).to eq(68.5)
  #       expect(ed_2.tip_outs_given_cash.round(1)).to eq(9.8)
  #       expect(ed_2.tip_outs_received_cc.round(1)).to eq(0)
  #       expect(ed_2.tip_outs_received_cash.round(1)).to eq(0)
  #     end

  #     it "should have right numbers for 2.1 employee distribution" do
  #       ed_3 = calculation.employee_distributions.where(employee: employee_2_1).first

  #       expect(ed_3.cc_tips_distr.round(1)).to eq(856.4)
  #       expect(ed_3.cash_tips_distr.round(1)).to eq(122.4)
  #       expect(ed_3.cc_tips_distr_final.round(1)).to eq(813.58)
  #       expect(ed_3.cash_tips_distr_final.round(1)).to eq(116.29)
  #       expect(ed_3.tip_outs_given_cc.round(1)).to eq(42.82)
  #       expect(ed_3.tip_outs_given_cash.round(1)).to eq(6.12)
  #       expect(ed_3.tip_outs_received_cc.round(1)).to eq(0)
  #       expect(ed_3.tip_outs_received_cash.round(1)).to eq(0)
  #     end

  #     it "should have right numbers for 3.1 employee distribution" do
  #       ed_4 = calculation.employee_distributions.where(employee: employee_3_1).first

  #       expect(ed_4.cc_tips_distr.round(1)).to eq(685.1)
  #       expect(ed_4.cash_tips_distr.round(1)).to eq(97.9)
  #       expect(ed_4.cc_tips_distr_final.round(1)).to eq(650.86)
  #       expect(ed_4.cash_tips_distr_final.round(1)).to eq(93.03)
  #       expect(ed_4.tip_outs_given_cc.round(1)).to eq(34.26)
  #       expect(ed_4.tip_outs_given_cash.round(1)).to eq(4.90)
  #       expect(ed_4.tip_outs_received_cc.round(1)).to eq(0)
  #       expect(ed_4.tip_outs_received_cash.round(1)).to eq(0)
  #     end

  #     it "should have right numbers for 3.2 employee distribution" do
  #       ed_5 = calculation.employee_distributions.where(employee: employee_3_2).first

  #       expect(ed_5.cc_tips_distr.round(1)).to eq(685.1)
  #       expect(ed_5.cash_tips_distr.round(1)).to eq(97.9)
  #       expect(ed_5.cc_tips_distr_final.round(1)).to eq(650.86)
  #       expect(ed_5.cash_tips_distr_final.round(1)).to eq(93.03)
  #       expect(ed_5.tip_outs_given_cc.round(1)).to eq(34.26)
  #       expect(ed_5.tip_outs_given_cash.round(1)).to eq(4.90)
  #       expect(ed_5.tip_outs_received_cc.round(1)).to eq(0)
  #       expect(ed_5.tip_outs_received_cash.round(1)).to eq(0)
  #     end

  #     it "#total_tip_outs_given_percentage" do
  #       expect(calculation.total_tip_outs_given_percentage).to eq(5)
  #     end

  #     it "#total_tip_outs_given_cc" do
  #       expect(calculation.total_tip_outs_given_cc.round(2)).to eq(248.36)
  #     end

  #     it "#total_tip_outs_given_cash" do
  #       expect(calculation.total_tip_outs_given_cash.round(2)).to eq(35.5)
  #     end

  #     it "#total_tip_outs_received_cc" do
  #       expect(calculation.total_tip_outs_received_cc.round(2)).to eq(0)
  #     end

  #     it "#total_tip_outs_received_cash" do
  #       expect(calculation.total_tip_outs_received_cash.round(2)).to eq(0)
  #     end

  #     it "#total_tips_distributed_cc" do
  #       expect(calculation.total_tips_distributed_cc.round(2)).to eq(4718.7)
  #     end

  #     it "#total_tips_distributed_cash" do
  #       expect(calculation.total_tips_distributed_cash.round(2)).to eq(674.5)
  #     end

  #     it "#total_tips_distributed_global" do
  #       expect(calculation.total_tips_distributed_global.round(2)).to eq(5393.2)
  #     end
  #   end
  # end

  context "simple points calculation with received tip outs exist" do
    let!(:captain){ FactoryGirl.create(:position_type_with_employees, name: "captain", restaurant: restaurant) }

    before :each do
      calculation.percent_distributions.create(position_type: captain, percentage: 0)

      AreaShift.all.each do |f|
        f.days = AreaShift::DAYS
        f.position_types = restaurant.position_types
        f.save;
      end

      restaurant.reload
      calculation.reload
    end

    context "additional position added" do
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
      let!(:percantage_4) { calculation.percent_distributions[3] }

      let!(:employee_1_1) { percantage_1.position_type.employees.first }
      let!(:employee_1_2) { percantage_1.position_type.employees.second }
      let!(:employee_1_3) { percantage_1.position_type.employees.third }
      let!(:employee_2_1) { percantage_2.position_type.employees.first }
      let!(:employee_2_2) { percantage_2.position_type.employees.second }
      let!(:employee_3_1) { percantage_3.position_type.employees.first }

      let!(:tip_out_received) { TipOut.create(
        percentage: 5,
        cc_summ: 24.84,
        cash_summ: 3.55,
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
          "distribution_type" => "points",
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
                                      "cc" => "359.71",
                                      "cash" => "110.0"
                                  },
                                  "totalMoneyOut" => {},
                                  "totalTipOutsGiven" => {},
                                  "totalTipOutsReceived" => {},
                                  "finalMoneyToDistribute" => {}
                              },
                              "#{ employee_1_2.id }" => {
                                  "hoursWorkedInHours" => "1",
                                  "totalMoneyIn" => {
                                      "cc" => "256.15",
                                      "cash" => "0.0"
                                  },
                                  "totalMoneyOut" => {},
                                  "totalTipOutsGiven" => {},
                                  "totalTipOutsReceived" => {},
                                  "finalMoneyToDistribute" => {}
                              },
                              "#{ employee_1_3.id }" => {
                                  "hoursWorkedInHours" => "1",
                                  "totalMoneyIn" => {
                                      "cc" => "118.97",
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
                              "#{ employee_2_1.id }" => {
                                  "hoursWorkedInHours" => "1",
                                  "totalMoneyOut" => {},
                                  "totalTipOutsGiven" => {},
                                  "totalTipOutsReceived" => {},
                                  "finalMoneyToDistribute" => {}
                              },
                              "#{ employee_2_2.id }" => {
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
                              "#{ employee_3_1.id }" => {
                                  "hoursWorkedInHours" => "2",
                                  "totalMoneyOut" => {},
                                  "totalTipOutsGiven" => {},
                                  "totalTipOutsReceived" => {},
                                  "finalMoneyToDistribute" => {}
                              }
                          }
                      }
                  }
              },
              "#{ percantage_4.position_type.name }" => {
                  "positionTypeIsASource" => "false",
                  "teams" => {
                      "1" => {
                          "employees" => {
                          }
                      }
                  }
              }
          },

          "percentage" => {
              "#{ percantage_1.id }" => "8",
              "#{ percantage_2.id }" => "5",
              "#{ percantage_3.id }" => "2.5",
              "#{ percantage_4.id }" => "6",
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
        expect(calculation.received_tip_outs.first.percentage).to eq(5)
        expect(calculation.received_tip_outs.first.cc_summ).to eq(24.84)
        expect(calculation.received_tip_outs.first.cash_summ).to eq(3.55)
      end

      it "should have 3 employee distributions" do
        expect(calculation.reload.employee_distributions.count).to eq(6)
      end

      it "should have right input money numbers in employee distributions for source type" do
        ed_1 = calculation.employee_distributions.find_by(employee: employee_1_1)
        expect(ed_1.cc_tips).to eq(359.71)
        expect(ed_1.cash_tips).to eq(110)

        ed_2 = calculation.employee_distributions.find_by(employee: employee_1_2)
        expect(ed_2.cc_tips).to eq(256.15)
        expect(ed_2.cash_tips).to eq(0)

        ed_3 = calculation.employee_distributions.find_by(employee: employee_1_3)
        expect(ed_3.cc_tips).to eq(118.97)
        expect(ed_3.cash_tips).to eq(0)
      end

      it "should have right numbers for 3 employee distributions" do
        [employee_1_1, employee_1_2, employee_1_3].each do |employee|
          ed = calculation.employee_distributions.find_by(employee: employee)

          expect(ed.cc_tips_distr.round(2)).to eq(150.73)
          expect(ed.cash_tips_distr.round(2)).to eq(22.56)
          expect(ed.tip_outs_given_cc.round(2)).to eq(0)
          expect(ed.tip_outs_given_cash.round(2)).to eq(0)
          expect(ed.tip_outs_received_cc.round(2)).to eq(5.10)
          expect(ed.tip_outs_received_cash.round(2)).to eq(0.73)

          expect(ed.cc_tips_distr_final.round(2)).to eq(155.83)
          expect(ed.cash_tips_distr_final.round(2)).to eq(23.29)
        end
      end

      it "should have right numbers for 2 employee distributions" do
        [employee_2_1, employee_2_2].each do |employee|
          ed = calculation.employee_distributions.find_by(employee: employee)

          expect(ed.cc_tips_distr.round(2)).to eq(94.21)
          expect(ed.cash_tips_distr.round(2)).to eq(14.10)
          expect(ed.tip_outs_given_cc.round(2)).to eq(0)
          expect(ed.tip_outs_given_cash.round(2)).to eq(0)
          expect(ed.tip_outs_received_cc.round(2)).to eq(3.18)
          expect(ed.tip_outs_received_cash.round(2)).to eq(0.46)

          expect(ed.cc_tips_distr_final.round(2)).to eq(97.39)
          expect(ed.cash_tips_distr_final.round(2)).to eq(14.56)
        end
      end

      it "should have right numbers for 1 employee distribution" do
        [employee_3_1].each do |employee|
          ed = calculation.employee_distributions.find_by(employee: employee)

          expect(ed.cc_tips_distr.round(2)).to eq(94.21)
          expect(ed.cash_tips_distr.round(2)).to eq(14.10)
          expect(ed.tip_outs_given_cc.round(2)).to eq(0)
          expect(ed.tip_outs_given_cash.round(2)).to eq(0)
          expect(ed.tip_outs_received_cc.round(2)).to eq(3.18)
          expect(ed.tip_outs_received_cash.round(2)).to eq(0.46)

          expect(ed.cc_tips_distr_final.round(2)).to eq(97.39)
          expect(ed.cash_tips_distr_final.round(2)).to eq(14.56)
        end
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
        expect(calculation.total_tip_outs_received_cc).to eq(24.84)
      end

      it "#total_tip_outs_received_cash" do
        expect(calculation.total_tip_outs_received_cash).to eq(3.55)
      end

      it "#total_tips_distributed_cc" do
        expect(calculation.total_tips_distributed_cc.round(2)).to eq(759.67)
      end

      it "#total_tips_distributed_cash" do
        expect(calculation.total_tips_distributed_cash.round(2)).to eq(113.55)
      end

      it "#total_tips_distributed_global" do
        expect(calculation.total_tips_distributed_global.round(2)).to eq(873.22)
      end
    end
  end
end
