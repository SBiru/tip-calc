require 'rails_helper'

describe ReportsHelper do
  let!(:restaurant) do
    FactoryGirl.create(:seeded_restaurant, user: FactoryGirl.create(:user))
  end
  let!(:calculation) do
    FactoryGirl.create(:calculation,
      restaurant: restaurant.reload,
      user: restaurant.user,
      shift_type: restaurant.shift_types.first,
      area_type: restaurant.area_types.first,
      source_positions: [restaurant.position_types.first],
      distribution_type: "percents"
    )
  end

  let!(:date_params) do
    {
      start: Time.zone.now.to_date.strftime('%m/%d/%Y'),
      end: Time.zone.now.to_date.strftime('%m/%d/%Y'),
      area_type_id: 'All',
      shift_type_id: 'All',
      position_type_id: 'All',
      employee_id: 'All',
      show_totals: true
    }
  end

  context 'simple calculation without tip outs exist' do
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
                                "totalMoneyOut" => {
                                  "cc" => "30",
                                  "cash" => "60"
                                },
                                "totalTipOutsGiven" => {},
                                "totalTipOutsReceived" => {},
                                "finalMoneyToDistribute" => {
                                  "cc" => "30",
                                  "cash" => "60"
                                }
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
                                "totalMoneyOut" => {
                                  "cc" => "20",
                                  "cash" => "40"
                                },
                                "totalTipOutsGiven" => {},
                                "totalTipOutsReceived" => {},
                                "finalMoneyToDistribute" => {
                                  "cc" => "20",
                                  "cash" => "40"
                                }
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
                                "finalMoneyToDistribute" => {
                                  "cc" => "50",
                                  "cash" => "100"
                                }
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

    it 'should return right options merged' do
      options_merged = ReportsHelper.options_merged(restaurant, date_params)
      expect(options_merged).to eq({date: Time.zone.now.to_date..Time.zone.now.to_date})
    end

    it 'should return right calculations' do
      calculations = Calculation.report_by(restaurant, date_params)
      expect(calculations).to eq([calculation])
    end

    describe "reports are being fetched" do
      let!(:calculations) { Calculation.report_by(restaurant, date_params) }
      let!(:reports) do
        ReportsHelper.get_reports(restaurant, calculations, date_params)
      end

      # begin=
        # it 'should have right dates' do
        #   expect(
        #     reports[:position_stat][position.id] = {
        #       name: position.name,
        #       employee_distributions: {
        #         "employee_id": {
        #           empoyee_data: emloyee,
        #           distributions: distributions,
        #           employee_totals: {
        #             cc:
        #             cash:
        #             total
        #             tip_outs {
        #               received
        #               given:
        #             }
        #           },

        #           day_distributions: {
        #             "date": {
        #               cc
        #               cash
        #               total
        #               tip_outs
        #                 given
        #                 received
        #             }
        #           }
        #         }
        #       }
        #       ,
        #       day_totals: {
        #         "date": {

        #           cc
        #           cash
        #           total
        #           tip_outs
        #             given
        #             received
        #         }
        #         },
        #       position_totals: {
        #         cc
        #         cash
        #         total
        #         tip_outs
        #           given
        #           received
        #       }
        #     }
        #   ).to eq([Time.zone.now.to_date])
        # end
      # =end

      it 'should have right dates' do
        expect(
          reports[:dates]
        ).to eq([Time.zone.now.to_date])
      end

      describe 'should have right position_totals' do
        it 'should have right cc summs' do
          expect(reports[:position_stat][percantage_1.position_type.id.to_s][:position_totals][:cc]).to eq(30.00)
          expect(reports[:position_stat][percantage_2.position_type.id.to_s][:position_totals][:cc]).to eq(20.00)
          expect(reports[:position_stat][percantage_3.position_type.id.to_s][:position_totals][:cc]).to eq(50.00)
        end

        it 'should have right cash summs' do
          expect(reports[:position_stat][percantage_1.position_type.id.to_s][:position_totals][:cash]).to eq(60.00)
          expect(reports[:position_stat][percantage_2.position_type.id.to_s][:position_totals][:cash]).to eq(40.00)
          expect(reports[:position_stat][percantage_3.position_type.id.to_s][:position_totals][:cash]).to eq(100.00)
        end

        it 'should have right total summs' do
          expect(reports[:position_stat][percantage_1.position_type.id.to_s][:position_totals][:total]).to eq(90.00)
          expect(reports[:position_stat][percantage_2.position_type.id.to_s][:position_totals][:total]).to eq(60.00)
          expect(reports[:position_stat][percantage_3.position_type.id.to_s][:position_totals][:total]).to eq(150.00)
        end

        it 'should have right tip_outs summs' do
          expect(reports[:position_stat][percantage_1.position_type.id.to_s][:position_totals][:tip_outs]).to eq({given: {cc: 0.00, cash: 0.00}, received: {cc: 0.00, cash: 0.00}})
          expect(reports[:position_stat][percantage_2.position_type.id.to_s][:position_totals][:tip_outs]).to eq({given: {cc: 0.00, cash: 0.00}, received: {cc: 0.00, cash: 0.00}})
          expect(reports[:position_stat][percantage_3.position_type.id.to_s][:position_totals][:tip_outs]).to eq({given: {cc: 0.00, cash: 0.00}, received: {cc: 0.00, cash: 0.00}})
        end
      end

      describe 'should have right employee totals' do
        let!(:employee_totals) do
          [
            reports[:position_stat][percantage_1.position_type.id.to_s][:employee_distributions][employee_1.id.to_s][:employee_totals],
            reports[:position_stat][percantage_2.position_type.id.to_s][:employee_distributions][employee_2.id.to_s][:employee_totals],
            reports[:position_stat][percantage_3.position_type.id.to_s][:employee_distributions][employee_3.id.to_s][:employee_totals]
          ]
        end
        it 'should have right cc summs' do
          expect(employee_totals[0][:cc]).to eq(30.00)
          expect(employee_totals[1][:cc]).to eq(20.00)
          expect(employee_totals[2][:cc]).to eq(50.00)
        end

        it 'should have right cash summs' do
          expect(employee_totals[0][:cash]).to eq(60.00)
          expect(employee_totals[1][:cash]).to eq(40.00)
          expect(employee_totals[2][:cash]).to eq(100.00)
        end

        it 'should have right total summs' do
          expect(employee_totals[0][:total]).to eq(90.00)
          expect(employee_totals[1][:total]).to eq(60.00)
          expect(employee_totals[2][:total]).to eq(150.00)
        end

        it 'should have right tip_outs summs' do
          expect(employee_totals[0][:tip_outs]).to eq({given: {cc: 0.00, cash: 0.00}, received: {cc: 0.00, cash: 0.00}})
          expect(employee_totals[1][:tip_outs]).to eq({given: {cc: 0.00, cash: 0.00}, received: {cc: 0.00, cash: 0.00}})
          expect(employee_totals[2][:tip_outs]).to eq({given: {cc: 0.00, cash: 0.00}, received: {cc: 0.00, cash: 0.00}})
        end
      end

      describe 'should have right emplloyee day totals' do
        let!(:day_distributions) do
          [
            reports[:position_stat][percantage_1.position_type.id.to_s][:employee_distributions][employee_1.id.to_s][:day_distributions][Time.zone.now.to_date],
            reports[:position_stat][percantage_2.position_type.id.to_s][:employee_distributions][employee_2.id.to_s][:day_distributions][Time.zone.now.to_date],
            reports[:position_stat][percantage_3.position_type.id.to_s][:employee_distributions][employee_3.id.to_s][:day_distributions][Time.zone.now.to_date]
          ]
        end

        it 'should have right cc summs' do
          expect(day_distributions[0][:cc]).to eq(30.00)
          expect(day_distributions[1][:cc]).to eq(20.00)
          expect(day_distributions[2][:cc]).to eq(50.00)
        end

        it 'should have right cash summs' do
          expect(day_distributions[0][:cash]).to eq(60.00)
          expect(day_distributions[1][:cash]).to eq(40.00)
          expect(day_distributions[2][:cash]).to eq(100.00)
        end

        it 'should have right total summs' do
          expect(day_distributions[0][:total]).to eq(90.00)
          expect(day_distributions[1][:total]).to eq(60.00)
          expect(day_distributions[2][:total]).to eq(150.00)
        end

        it 'should have right tip_outs summs' do
          expect(day_distributions[0][:tip_outs]).to eq({given: {cc: 0.00, cash: 0.00}, received: {cc: 0.00, cash: 0.00}})
          expect(day_distributions[1][:tip_outs]).to eq({given: {cc: 0.00, cash: 0.00}, received: {cc: 0.00, cash: 0.00}})
          expect(day_distributions[2][:tip_outs]).to eq({given: {cc: 0.00, cash: 0.00}, received: {cc: 0.00, cash: 0.00}})
        end
      end

      describe 'should have right day_totals' do
        let!(:day_totals) do
          [
            reports[:position_stat][percantage_1.position_type.id.to_s][:day_totals][Time.zone.now.to_date],
            reports[:position_stat][percantage_2.position_type.id.to_s][:day_totals][Time.zone.now.to_date],
            reports[:position_stat][percantage_3.position_type.id.to_s][:day_totals][Time.zone.now.to_date]
          ]
        end

        it 'should have right cc summs' do
          expect(day_totals[0][:cc]).to eq(30.00)
          expect(day_totals[1][:cc]).to eq(20.00)
          expect(day_totals[2][:cc]).to eq(50.00)
        end

        it 'should have right cash summs' do
          expect(day_totals[0][:cash]).to eq(60.00)
          expect(day_totals[1][:cash]).to eq(40.00)
          expect(day_totals[2][:cash]).to eq(100.00)
        end

        it 'should have right total summs' do
          expect(day_totals[0][:total]).to eq(90.00)
          expect(day_totals[1][:total]).to eq(60.00)
          expect(day_totals[2][:total]).to eq(150.00)
        end

        it 'should have right tip_outs summs' do
          expect(day_totals[0][:tip_outs]).to eq({given: {cc: 0.00, cash: 0.00}, received: {cc: 0.00, cash: 0.00}})
          expect(day_totals[1][:tip_outs]).to eq({given: {cc: 0.00, cash: 0.00}, received: {cc: 0.00, cash: 0.00}})
          expect(day_totals[2][:tip_outs]).to eq({given: {cc: 0.00, cash: 0.00}, received: {cc: 0.00, cash: 0.00}})
        end
      end

      describe "report totals" do
        describe "should be right 1 day all areas totals" do
          it "cc" do
            expect(reports[:totals][:cc][:cc_tips][:by_date][Time.zone.now.to_date]).to eq(100)
            # expect(reports[:totals][:cc][:cc_tips_sheets][:by_date][Time.zone.now.to_date]).to eq(100)
            # expect(reports[:totals][:cc][:total_cc_tips_variance][:by_date][Time.zone.now.to_date]).to eq(0)
          end

          it "cash" do
            expect(reports[:totals][:cash][:cash_tips][:by_date][Time.zone.now.to_date]).to eq(200)
            # expect(reports[:totals][:cash][:cash_tips_sheets][:by_date][Time.zone.now.to_date]).to eq(200)
            # expect(reports[:totals][:cash][:total_cash_tips_variance][:by_date][Time.zone.now.to_date]).to eq(0)
          end

          it "global" do
            expect(reports[:totals][:global][:global_tips][:by_date][Time.zone.now.to_date]).to eq(300)
            # expect(reports[:totals][:global][:global_tips_sheets][:by_date][Time.zone.now.to_date]).to eq(300)
            # expect(reports[:totals][:global][:total_global_tips_variance][:by_date][Time.zone.now.to_date]).to eq(0)
          end

          xit "pos data"
        end

        describe "should be right 1 day each areas totals" do
          it "cc" do
            expect(reports[:totals][:cc][:cc_tips][:by_date_and_area][calculation.area_type_id.to_s][:by_date][Time.zone.now.to_date]).to eq(100)
            # expect(reports[:totals][:cc][:cc_tips_sheets][:by_date_and_area][calculation.area_type_id.to_s][:by_date][Time.zone.now.to_date]).to eq(100)
            # expect(reports[:totals][:cc][:total_cc_tips_variance][:by_date_and_area][calculation.area_type_id.to_s][:by_date][Time.zone.now.to_date]).to eq(0)
          end

          it "cash" do
            expect(reports[:totals][:cash][:cash_tips][:by_date_and_area][calculation.area_type_id.to_s][:by_date][Time.zone.now.to_date]).to eq(200)
            # expect(reports[:totals][:cash][:cash_tips_sheets][:by_date_and_area][calculation.area_type_id.to_s][:by_date][Time.zone.now.to_date]).to eq(200)
            # expect(reports[:totals][:cash][:total_cash_tips_variance][:by_date_and_area][calculation.area_type_id.to_s][:by_date][Time.zone.now.to_date]).to eq(0)
          end

          it "global" do
            expect(reports[:totals][:global][:global_tips][:by_date_and_area][calculation.area_type_id.to_s][:by_date][Time.zone.now.to_date]).to eq(300)
            # expect(reports[:totals][:global][:global_tips_sheets][:by_date_and_area][calculation.area_type_id.to_s][:by_date][Time.zone.now.to_date]).to eq(300)
            # expect(reports[:totals][:global][:total_global_tips_variance][:by_date_and_area][calculation.area_type_id.to_s][:by_date][Time.zone.now.to_date]).to eq(0)
          end
        end
        describe "should be right all days all areas totals" do
          it "cc" do
            expect(reports[:totals][:cc][:cc_tips][:scope_total]).to eq(100)
            # expect(reports[:totals][:cc][:cc_tips_sheets][:scope_total]).to eq(100)
            # expect(reports[:totals][:cc][:total_cc_tips_variance][:scope_total]).to eq(0)
          end

          it "cash" do
            expect(reports[:totals][:cash][:cash_tips][:scope_total]).to eq(200)
            # expect(reports[:totals][:cash][:cash_tips_sheets][:scope_total]).to eq(200)
            # expect(reports[:totals][:cash][:total_cash_tips_variance][:scope_total]).to eq(0)
          end

          it "global" do
            expect(reports[:totals][:global][:global_tips][:scope_total]).to eq(300)
            # expect(reports[:totals][:global][:global_tips_sheets][:scope_total]).to eq(300)
            # expect(reports[:totals][:global][:total_global_tips_variance][:scope_total]).to eq(0)
          end
        end
        describe "should be right all days each areas totals" do
          it "cc" do
            expect(reports[:totals][:cc][:cc_tips][:by_area][calculation.area_type_id.to_s]).to eq(100)
            # expect(reports[:totals][:cc][:cc_tips_sheets][:by_area][calculation.area_type_id.to_s]).to eq(100)
            # expect(reports[:totals][:cc][:total_cc_tips_variance][:by_area][calculation.area_type_id.to_s]).to eq(0)
          end

          it "cash" do
            expect(reports[:totals][:cash][:cash_tips][:by_area][calculation.area_type_id.to_s]).to eq(200)
            # expect(reports[:totals][:cash][:cash_tips_sheets][:by_area][calculation.area_type_id.to_s]).to eq(200)
            # expect(reports[:totals][:cash][:total_cash_tips_variance][:by_area][calculation.area_type_id.to_s]).to eq(0)
          end

          it "global" do
            expect(reports[:totals][:global][:global_tips][:by_area][calculation.area_type_id.to_s]).to eq(300)
            # expect(reports[:totals][:global][:global_tips_sheets][:by_area][calculation.area_type_id.to_s]).to eq(300)
            # expect(reports[:totals][:global][:total_global_tips_variance][:by_area][calculation.area_type_id.to_s]).to eq(0)
          end
        end
      end
    end

    xit '#options_merged(restaurant, params)'
    xit '#options_merged_individual(date, area_type_id, shift_type_id)'

    xit '#get_excel_report(restaurant, calculations, params)'
    xit '#get_totals(area_type_id, shift_type_id, employee_id, dates, calculations)'
  end

  # context 'simple calculation witр given tip outs exist' do
  #   let!(:percantage_1) { calculation.percent_distributions[0] }
  #   let!(:percantage_2) { calculation.percent_distributions[1] }
  #   let!(:percantage_3) { calculation.percent_distributions[2] }

  #   let!(:employee_1) { percantage_1.position_type.employees.first }
  #   let!(:employee_2) { percantage_2.position_type.employees.first }
  #   let!(:employee_3) { percantage_3.position_type.employees.first }

  #   let!(:area_2) { restaurant.area_types.last }

  #   before :each do

  #     calculation.source_positions = [percantage_1.position_type]
  #     calculation.save

  #     @params = {
  #       "calculationId" => calculation.id,
  #       "distribution_type" => "percents",
  #       "posTotals" => {
  #           "calculationPosTotal" => "0",
  #           "dayPosTotal" => "0"
  #       },
  #       "tipOuts" => {
  #           "given" => {
  #               "cc" => "0",
  #               "cash" => "0"
  #           },
  #           "received" => {
  #               "cc" => "0",
  #               "cash" => "0"
  #           }
  #       },

  #       "positionsMoney" => {
  #           "#{ percantage_1.position_type.name }" => {
  #               "positionTypeIsASource" => "true",
  #               "teams" => {
  #                   "1" => {
  #                       "employees" => {
  #                           "#{ employee_1.id }" => {
  #                               "hoursWorkedInHours" => "1",
  #                               "totalMoneyIn" => {
  #                                   "cc" => "100.0",
  #                                   "cash" => "200.0"
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
  #                           "#{ employee_2.id }" => {
  #                               "hoursWorkedInHours" => "1"
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
  #                           "#{ employee_3.id }" => {
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
  #                   "percentage" => "25.00"
  #               }
  #           }
  #       },
  #       "percentage" => {
  #           "#{ percantage_1.id }" => "30",
  #           "#{ percantage_2.id }" => "20",
  #           "#{ percantage_3.id }" => "50",
  #       },
  #       "id" => calculation.id
  #     }

  #     calculation.update_calculation(@params)
  #   end
  # end

  # context 'simple calculation with multiple given tip outs exist' do

  #   let!(:percantage_1) { calculation.percent_distributions[0] }
  #   let!(:percantage_2) { calculation.percent_distributions[1] }
  #   let!(:percantage_3) { calculation.percent_distributions[2] }

  #   let!(:employee_1) { percantage_1.position_type.employees.first }
  #   let!(:employee_2) { percantage_2.position_type.employees.first }
  #   let!(:employee_3) { percantage_3.position_type.employees.first }

  #   let!(:area_2) { restaurant.area_types[1] }
  #   let!(:area_3) { restaurant.area_types[2] }

  #   before :each do

  #     calculation.source_positions = [percantage_1.position_type]
  #     calculation.save

  #     @params = {
  #       "calculationId" => calculation.id,
  #       "distribution_type" => "percents",
  #       "posTotals" => {
  #           "calculationPosTotal" => "0",
  #           "dayPosTotal" => "0"
  #       },
  #       "tipOuts" => {
  #           "given" => {
  #               "cc" => "0",
  #               "cash" => "0"
  #           },
  #           "received" => {
  #               "cc" => "0",
  #               "cash" => "0"
  #           }
  #       },

  #       "positionsMoney" => {
  #           "#{ percantage_1.position_type.name }" => {
  #               "positionTypeIsASource" => "true",
  #               "teams" => {
  #                   "1" => {
  #                       "employees" => {
  #                           "#{ employee_1.id }" => {
  #                               "hoursWorkedInHours" => "1",
  #                               "totalMoneyIn" => {
  #                                   "cc" => "100.0",
  #                                   "cash" => "200.0"
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
  #                           "#{ employee_2.id }" => {
  #                               "hoursWorkedInHours" => "1"
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
  #                           "#{ employee_3.id }" => {
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
  #                   "percentage" => "25.00"
  #               },
  #               "#{ area_3.name }" => {
  #                      "area_id" => area_3.id,
  #                   "percentage" => "25.00"
  #               }
  #           }
  #       },
  #       "percentage" => {
  #           "#{ percantage_1.id }" => "30",
  #           "#{ percantage_2.id }" => "20",
  #           "#{ percantage_3.id }" => "50",
  #       },
  #       "id" => calculation.id
  #     }

  #     calculation.update_calculation(@params)
  #   end
  # end

  # context "simple calculation with tip outs received" do
  #   let!(:sender_calculation) { FactoryGirl.create(:calculation,
  #     restaurant: restaurant.reload,
  #     user: restaurant.user,
  #     shift_type: restaurant.shift_types.first,
  #     area_type: restaurant.area_types.first,
  #     source_position_type: restaurant.position_types.first
  #     )
  #   }

  #   let!(:percantage_1) { calculation.percent_distributions[0] }
  #   let!(:percantage_2) { calculation.percent_distributions[1] }
  #   let!(:percantage_3) { calculation.percent_distributions[2] }

  #   let!(:employee_1) { percantage_1.position_type.employees.first }
  #   let!(:employee_2) { percantage_2.position_type.employees.first }
  #   let!(:employee_3) { percantage_3.position_type.employees.first }

  #   let!(:tip_out_received) { TipOut.create(
  #     percentage: 50,
  #     cc_summ: 50,
  #     cash_summ: 100,
  #     receiver_calculation: calculation,
  #     sender_calculation: sender_calculation,
  #     date: calculation.date,
  #     sender: sender_calculation.area_type,
  #     receiver: calculation.area_type,
  #     shift_type: calculation.shift_type
  #     )
  #   }

  #   before :each do

  #     calculation.source_positions = [percantage_1.position_type]
  #     calculation.save

  #     @params = {
  #       "calculationId" => calculation.id,
  #       "distribution_type" => "percents",
  #       "posTotals" => {
  #           "calculationPosTotal" => "0",
  #           "dayPosTotal" => "0"
  #       },
  #       "tipOuts" => {
  #           "given" => {
  #               "cc" => "0",
  #               "cash" => "0"
  #           },
  #           "received" => {
  #               "cc" => "0",
  #               "cash" => "0"
  #           }
  #       },

  #       "positionsMoney" => {
  #           "#{ percantage_1.position_type.name }" => {
  #               "positionTypeIsASource" => "true",
  #               "teams" => {
  #                   "1" => {
  #                       "employees" => {
  #                           "#{ employee_1.id }" => {
  #                               "hoursWorkedInHours" => "1",
  #                               "totalMoneyIn" => {
  #                                   "cc" => "100.0",
  #                                   "cash" => "200.0"
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
  #                           "#{ employee_2.id }" => {
  #                               "hoursWorkedInHours" => "1"
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
  #                           "#{ employee_3.id }" => {
  #                               "hoursWorkedInHours" => "1"
  #                           }
  #                       }
  #                   }
  #               }
  #           }
  #       },

  #       "percentage" => {
  #           "#{ percantage_1.id }" => "30",
  #           "#{ percantage_2.id }" => "20",
  #           "#{ percantage_3.id }" => "50",
  #       },
  #       "id" => calculation.id
  #     }

  #     calculation.update_calculation(@params)
  #   end
  # end

  # context "calculation with both given and received tip outs" do
  #   let!(:sender_calculation) { FactoryGirl.create(:calculation,
  #     restaurant: restaurant.reload,
  #     user: restaurant.user,
  #     shift_type: restaurant.shift_types.first,
  #     area_type: restaurant.area_types.first,
  #     source_position_type: restaurant.position_types.first
  #     )
  #   }

  #   let!(:percantage_1) { calculation.percent_distributions[0] }
  #   let!(:percantage_2) { calculation.percent_distributions[1] }
  #   let!(:percantage_3) { calculation.percent_distributions[2] }

  #   let!(:employee_1) { percantage_1.position_type.employees.first }
  #   let!(:employee_2) { percantage_2.position_type.employees.first }
  #   let!(:employee_3) { percantage_3.position_type.employees.first }

  #   let!(:area_2) { restaurant.area_types[1] }
  #   let!(:area_3) { restaurant.area_types[2] }

  #   let!(:tip_out_received) { TipOut.create(
  #     percentage: 50,
  #     cc_summ: 60,
  #     cash_summ: 120,
  #     receiver_calculation: calculation,
  #     sender_calculation: sender_calculation,
  #     date: calculation.date,
  #     sender: sender_calculation.area_type,
  #     receiver: calculation.area_type,
  #     shift_type: calculation.shift_type
  #     )
  #   }

  #   before :each do

  #     calculation.source_positions = [percantage_1.position_type]
  #     calculation.save

  #     @params = {
  #       "calculationId" => calculation.id,
  #       "distribution_type" => "percents",
  #       "posTotals" => {
  #           "calculationPosTotal" => "0",
  #           "dayPosTotal" => "0"
  #       },
  #       "tipOuts" => {
  #           "given" => {
  #               "cc" => "0",
  #               "cash" => "0"
  #           },
  #           "received" => {
  #               "cc" => "0",
  #               "cash" => "0"
  #           }
  #       },

  #       "positionsMoney" => {
  #           "#{ percantage_1.position_type.name }" => {
  #               "positionTypeIsASource" => "true",
  #               "teams" => {
  #                   "1" => {
  #                       "employees" => {
  #                           "#{ employee_1.id }" => {
  #                               "hoursWorkedInHours" => "1",
  #                               "totalMoneyIn" => {
  #                                   "cc" => "100.0",
  #                                   "cash" => "200.0"
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
  #                           "#{ employee_2.id }" => {
  #                               "hoursWorkedInHours" => "1"
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
  #                           "#{ employee_3.id }" => {
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
  #                   "percentage" => "25.00"
  #               },
  #               "#{ area_3.name }" => {
  #                      "area_id" => area_3.id,
  #                   "percentage" => "25.00"
  #               }
  #           }
  #       },
  #       "percentage" => {
  #           "#{ percantage_1.id }" => "30",
  #           "#{ percantage_2.id }" => "20",
  #           "#{ percantage_3.id }" => "50",
  #       },
  #       "id" => calculation.id
  #     }

  #     calculation.update_calculation(@params)
  #   end
  # end

  # context "simple calculation with multiple employees in 1 team exist" do
  #   let!(:sender_calculation) { FactoryGirl.create(:calculation,
  #     restaurant: restaurant.reload,
  #     user: restaurant.user,
  #     shift_type: restaurant.shift_types.first,
  #     area_type: restaurant.area_types.first,
  #     source_position_type: restaurant.position_types.first
  #     )
  #   }

  #   let!(:percantage_1) { calculation.percent_distributions[0] }
  #   let!(:percantage_2) { calculation.percent_distributions[1] }

  #   let!(:employee_1_from_team_1) { percantage_1.position_type.employees.first }
  #   let!(:employee_2_from_team_1) { percantage_1.position_type.employees.second }
  #   let!(:employee_3) { percantage_2.position_type.employees.first }

  #   let!(:area_2) { restaurant.area_types.last }

  #   let!(:tip_out_received) { TipOut.create(
  #     percentage: 50,
  #     cc_summ: 10,
  #     cash_summ: 20,
  #     receiver_calculation: calculation,
  #     sender_calculation: sender_calculation,
  #     date: calculation.date,
  #     sender: sender_calculation.area_type,
  #     receiver: calculation.area_type,
  #     shift_type: calculation.shift_type
  #     )
  #   }

  #   before :each do

  #     calculation.source_positions = [percantage_1.position_type]
  #     calculation.save

  #     @params = {
  #       "calculationId" => calculation.id,
  #       "distribution_type" => "percents",
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
  #                           "#{ employee_1_from_team_1.id }" => {
  #                               "hoursWorkedInHours" => "10",
  #                               "totalMoneyIn" => {
  #                                   "cc" => "100.0",
  #                                   "cash" => "200.0"
  #                               }
  #                           },
  #                           "#{ employee_2_from_team_1.id }" => {
  #                               "hoursWorkedInHours" => "5",
  #                               "totalMoneyIn" => {
  #                                   "cc" => "50.0",
  #                                   "cash" => "100.0"
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
  #                           "#{ employee_3.id }" => {
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
  #                   "percentage" => "25.00"
  #               }
  #           }
  #       },
  #       "percentage" => {
  #           "#{ percantage_1.id }" => "50",
  #           "#{ percantage_2.id }" => "50",
  #       },
  #       "id" => calculation.id
  #     }

  #     calculation.update_calculation(@params)
  #   end
  # end

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
  #       "tipOuts" => {
  #           "given" => {
  #               "cc" => "0",
  #               "cash" => "0"
  #           },
  #           "received" => {
  #               "cc" => "0",
  #               "cash" => "0"
  #           }
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
  # end

  # context "simple points calculation with received tip outs exist" do
  #   let!(:captain){ FactoryGirl.create(:position_type_with_employees, name: "captain", restaurant: restaurant) }

  #   before :each do
  #     calculation.percent_distributions.create(position_type: captain, percentage: 0)

  #     AreaShift.all.each do |f|
  #       f.days = AreaShift::DAYS
  #       f.position_types = restaurant.position_types
  #       f.save;
  #     end

  #     restaurant.reload
  #     calculation.reload
  #   end

  #   context "additional position added" do
  #     let!(:sender_calculation) { FactoryGirl.create(:calculation,
  #       restaurant: restaurant.reload,
  #       user: restaurant.user,
  #       shift_type: restaurant.shift_types.first,
  #       area_type: restaurant.area_types.first,
  #       source_position_type: restaurant.position_types.first
  #       )
  #     }

  #     let!(:percantage_1) { calculation.percent_distributions[0] }
  #     let!(:percantage_2) { calculation.percent_distributions[1] }
  #     let!(:percantage_3) { calculation.percent_distributions[2] }
  #     let!(:percantage_4) { calculation.percent_distributions[3] }

  #     let!(:employee_1_1) { percantage_1.position_type.employees.first }
  #     let!(:employee_1_2) { percantage_1.position_type.employees.second }
  #     let!(:employee_1_3) { percantage_1.position_type.employees.third }
  #     let!(:employee_2_1) { percantage_2.position_type.employees.first }
  #     let!(:employee_2_2) { percantage_2.position_type.employees.second }
  #     let!(:employee_3_1) { percantage_3.position_type.employees.first }

  #     let!(:tip_out_received) { TipOut.create(
  #       percentage: 5,
  #       cc_summ: 24.84,
  #       cash_summ: 3.55,
  #       receiver_calculation: calculation,
  #       sender_calculation: sender_calculation,
  #       date: calculation.date,
  #       sender: sender_calculation.area_type,
  #       receiver: calculation.area_type,
  #       shift_type: calculation.shift_type
  #       )
  #     }

  #     before :each do
  #       calculation.source_positions = [percantage_1.position_type]
  #       calculation.save

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
  #                                 "totalMoneyIn" => {
  #                                     "cc" => "359.71",
  #                                     "cash" => "110.0"
  #                                 }
  #                             },
  #                             "#{ employee_1_2.id }" => {
  #                                 "hoursWorkedInHours" => "1",
  #                                 "totalMoneyIn" => {
  #                                     "cc" => "256.15",
  #                                     "cash" => "0.0"
  #                                 }
  #                             },
  #                             "#{ employee_1_3.id }" => {
  #                                 "hoursWorkedInHours" => "1",
  #                                 "totalMoneyIn" => {
  #                                     "cc" => "118.97",
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
  #                                 "hoursWorkedInHours" => "1"
  #                             },
  #                             "#{ employee_2_2.id }" => {
  #                                 "hoursWorkedInHours" => "1"
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
  #                                 "hoursWorkedInHours" => "2"
  #                             }
  #                         }
  #                     }
  #                 }
  #             },
  #             "#{ percantage_4.position_type.name }" => {
  #                 "positionTypeIsASource" => "false",
  #                 "teams" => {
  #                     "1" => {
  #                         "employees" => {
  #                         }
  #                     }
  #                 }
  #             }
  #         },

  #         "percentage" => {
  #             "#{ percantage_1.id }" => "8",
  #             "#{ percantage_2.id }" => "5",
  #             "#{ percantage_3.id }" => "2.5",
  #             "#{ percantage_4.id }" => "6",
  #         },

  #         "id" => calculation.id
  #       }

  #       calculation.update_calculation(@params)
  #     end
  #   end
  # end

  xit '#options_merged(restaurant, params)'
  xit '#options_merged_individual(date, area_type_id, shift_type_id)'
  xit '#total_system(date, area_type_id, shift_type_id, employee_id)'
  xit '#total_tips(type, date, area_type_id, shift_type_id, employee_id)'
  xit '#total_tips_sheets(type, date, area_type_id, shift_type_id, employee_id)'
  xit '#total_tips_variance(type, date, area_type_id, shift_type_id, employee_id)'
  xit '#total_pos_variance(date, area_type_id, shift_type_id, employee_id)'
  xit '#to_float(number)'
  xit '#get_reports(restaurant, calculations, params)'
  xit '#get_excel_report(restaurant, calculations, params)'
  xit '#get_totals(area_type_id, shift_type_id, employee_id, dates, calculations)'
end
