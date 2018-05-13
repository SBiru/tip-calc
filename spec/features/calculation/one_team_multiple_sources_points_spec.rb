require 'capybara/rspec'
require 'spec_helper'

feature 'Frontend calculations' do
  let!(:restaurant) { FactoryGirl.create(:seeded_restaurant, user: FactoryGirl.create(:user)) }
  let!(:user) { restaurant.user }
  let!(:calculation) {
    FactoryGirl.create(:calculation,
      restaurant: restaurant.reload,
      user: restaurant.user,
      shift_type: restaurant.shift_types.first,
      area_type: restaurant.area_types.first,
      source_position_ids: [restaurant.position_types.first.id.to_s, restaurant.position_types.second.id.to_s],
      distribution_type: "points"
    )
  }

  before :each do
    sign_in_as user

    AreaShift.all.each do |f|
      f.days = AreaShift::DAYS
      f.position_types = restaurant.position_types
      f.save;
    end

    AreaType.all.each do |f|
      f.activate
    end

    restaurant.reload
  end
  
  feature "filling calculations in front end from scratch", js: true do
    include_context :gon

    let!(:source_position_first) { restaurant.position_types.first }
    let!(:source_position_second) { restaurant.position_types.second }
    feature "INTEGRATED: point calculations" do
      let!(:not_source_position_first) { restaurant.position_types.third }

      let!(:area_2) { restaurant.area_types.second }
      let!(:area_3) { restaurant.area_types.third }

      feature "1 team" do
        feature "3 source employees + 6 nonsource employees (2 teams) + 2 given tip outs + 1 received" do
          let!(:sender_calculation) {
            FactoryGirl.create(:calculation,
              restaurant: restaurant.reload,
              user: restaurant.user,
              shift_type: restaurant.shift_types.first,
              area_type: restaurant.area_types.last,
              source_position_ids: [restaurant.position_types.first.id.to_s],
              distribution_type: "percents"
            )
          }

          let!(:tip_out_received) {TipOut.create(
            percentage: 10,
            cc_summ: 3,
            cash_summ: 2,
            receiver_calculation: calculation,
            sender_calculation: sender_calculation,
            date: calculation.date,
            sender: sender_calculation.area_type,
            receiver: calculation.area_type,
            shift_type: calculation.shift_type
            )
          }

          before :each do
            visit show_calculation_get_path(calculation_id: calculation.id.to_s)

            within("#percentage #positions-table") do
              find(:css, ".total-position-tips[data-position-type='#{ source_position_first.name }'] .percentage-point").set '5'
              find(:css, ".total-position-tips[data-position-type='#{ source_position_second.name }'] .percentage-point").set '3.6'
              find(:css, ".total-position-tips[data-position-type='#{ not_source_position_first.name }'] .percentage-point").set '5'
            end

            # SOURCE POSITIONS

            # Add 3 source employees
            within("#distributions-list") do
              find("[data-action='add-employee'][data-position='#{ source_position_first.name }']").click
              find("[data-action='add-employee'][data-position='#{ source_position_first.name }']").click
              find("[data-action='add-employee'][data-position='#{ source_position_first.name }']").click
            end

            # Fill collected money
            within(".employee-distribution-line[data-employee-id='#{ source_position_first.employees.first.id }']") do
              find(:css, ".number-hrs").set '8'
              find(:css, ".cc-in input").set '100'
              find(:css, ".cash-in input").set '9'
            end
            within(".employee-distribution-line[data-employee-id='#{ source_position_first.employees.second.id }']") do
              find(:css, ".number-hrs").set '9'
              find(:css, ".cc-in input").set '200'
              find(:css, ".cash-in input").set '18'
            end
            within(".employee-distribution-line[data-employee-id='#{ source_position_first.employees.third.id }']") do
              find(:css, ".number-hrs").set '10'
              find(:css, ".cc-in input").set '300'
              find(:css, ".cash-in input").set '27'
            end

            # Add 3 source employees
            within("#distributions-list") do
              find("[data-action='add-employee'][data-position='#{ source_position_second.name }']").click
              find("[data-action='add-employee'][data-position='#{ source_position_second.name }']").click
              find("[data-action='add-employee'][data-position='#{ source_position_second.name }']").click
            end

            # Fill collected money
            within(".employee-distribution-line[data-employee-id='#{ source_position_second.employees.first.id }']") do
              find(:css, ".number-hrs").set '8'
              find(:css, ".cc-in input").set '200'
              find(:css, ".cash-in input").set '18'
            end
            within(".employee-distribution-line[data-employee-id='#{ source_position_second.employees.second.id }']") do
              find(:css, ".number-hrs").set '9'
              find(:css, ".cc-in input").set '300'
              find(:css, ".cash-in input").set '27'
            end
            within(".employee-distribution-line[data-employee-id='#{ source_position_second.employees.third.id }']") do
              find(:css, ".number-hrs").set '10'
              find(:css, ".cc-in input").set '400'
              find(:css, ".cash-in input").set '36'
            end

            # NON-SOURCE POSITIONS

            # Add 1 non-source employee
            within("#distributions-list") do
              find("[data-action='add-employee'][data-position='#{ not_source_position_first.name }']").click
              find("[data-action='add-employee'][data-position='#{ not_source_position_first.name }']").click
              find("[data-action='add-employee'][data-position='#{ not_source_position_first.name }']").click
            end
            within(".employee-distribution-line[data-employee-id='#{ not_source_position_first.employees.first.id }']") do
              find(:css, ".number-hrs").set '8'
            end
            within(".employee-distribution-line[data-employee-id='#{ not_source_position_first.employees.second.id }']") do
              find(:css, ".number-hrs").set '9'
            end
            within(".employee-distribution-line[data-employee-id='#{ not_source_position_first.employees.third.id }']") do
              find(:css, ".number-hrs").set '10'
            end

            # TIP OUTS

            within(".percentage-block") do
              find("a[href='#tip-out']").click
            end

            # Add tip out to 1 area

            find("#tip-out.active [data-action='add-area']").click

            all(".tip-out-line .area-type-select-wrapper .select2-container").first.click
            find(".select2-results__option", text: area_2.name.titleize).click
            all(".tip-out-line .tip-out-percentage").first.set 10

            # Show tip outs
            find(".toggle-tip-outs-wrapper .iCheck-helper").click
          end

          scenario "should have received tip outs" do
            within(".percentage-block") do
              within("#received-tipouts-table .received-tip-out-line[data-area-name='#{ tip_out_received.sender.name }']") do
                expect(page).to have_css ".cc-received", text: "3"
                expect(page).to have_css ".cash-received", text: "2"
              end
            end
          end

          scenario "should have given tip outs" do
            within(".percentage-block") do
              find("a[href='#tip-out']").click

              within("#given-tipouts-table") do
                within all(".tip-out-line").first do
                  expect(page).to have_css ".cc_summ", text: "150"
                  expect(page).to have_css ".cash_summ", text: "13.5"
                end
              end
            end
          end

          scenario "should have right totals table" do
            within("#total-block") do
              expect(page).to have_css ".cc-out-total", text: '1500'
              expect(page).to have_css ".cash-out-total", text: '135'
              expect(page).to have_css ".tip-outs-given-cc", text: '150'
              expect(page).to have_css ".tip-outs-given-cash", text: '13.5'
              expect(page).to have_css ".tip-outs-received-cc", text: '3'
              expect(page).to have_css ".tip-outs-received-cash", text: '2'
              expect(page).to have_css ".tips-distributed-cc", text: '1353'
              expect(page).to have_css ".tips-distributed-cash", text: '123.50'
              expect(page).to have_css ".tips-to-distribute-cc", text: '1353.00'
              expect(page).to have_css ".tips-to-distribute-cash", text: '123.50'
              expect(page).to have_css ".hours", text: '81'
            end
          end

          scenario "should have right percentage table numbers" do
            find("a[href='#percentage']").click

            within("#percentage #positions-table") do
              within ".total-position-tips[data-position-type='#{ source_position_first.name }']" do
                expect(page).to have_css ".total-position-cc-tips", text: "496.32"
                expect(page).to have_css ".total-position-cash-tips", text: "44.67"
              end
              within ".total-position-tips[data-position-type='#{ source_position_second.name }']" do
                expect(page).to have_css ".total-position-cc-tips", text: "357.35"
                expect(page).to have_css ".total-position-cash-tips", text: "32.16"
              end
              within ".total-position-tips[data-position-type='#{ not_source_position_first.name }']" do
                expect(page).to have_css ".total-position-cc-tips", text: "496.32"
                expect(page).to have_css ".total-position-cash-tips", text: "44.67"
              end

              expect(page).to have_css ".total-tip-out-summ .percentage-point span", text: "10"
              expect(page).to have_css ".total-tip-out-summ .total-tip-out-cc-tips", text: "150"
              expect(page).to have_css ".total-tip-out-summ .total-tip-out-cash-tips", text: "13.5"

              expect(page).to have_css ".total .percentage-total", text: "367.2"
              expect(page).to have_css ".total .total-collected-cc-tips", text: "1500"
              expect(page).to have_css ".total .total-collected-cash-tips", text: "135"
            end
          end

          scenario "should have right employee calculations for source positions" do
            within(".employee-distribution-line[data-employee-id='#{ source_position_first.employees.first.id }']") do
              expect(page).to have_css ".cc-out", text: "163.4"
              expect(page).to have_css ".cash-out", text: "14.71"
              expect(page).to have_css ".tip-outs-given-cc", text: "16.34"
              expect(page).to have_css ".tip-outs-given-cash", text: "1.47"
              expect(page).to have_css ".tip-outs-received-cc", text: "0.33"
              expect(page).to have_css ".tip-outs-received-cash", text: "0.22"
              expect(page).to have_css ".final-tips-distributed-cc", text: "147.39"
              expect(page).to have_css ".final-tips-distributed-cash", text: "13.45"
            end
            within(".employee-distribution-line[data-employee-id='#{ source_position_first.employees.second.id }']") do
              expect(page).to have_css ".cc-out", text: "183.82"
              expect(page).to have_css ".cash-out", text: "16.54"
              expect(page).to have_css ".tip-outs-given-cc", text: "18.38"
              expect(page).to have_css ".tip-outs-given-cash", text: "1.65"
              expect(page).to have_css ".tip-outs-received-cc", text: "0.37"
              expect(page).to have_css ".tip-outs-received-cash", text: "0.25"
              expect(page).to have_css ".final-tips-distributed-cc", text: "165.81"
              expect(page).to have_css ".final-tips-distributed-cash", text: "15.13"
            end
            within(".employee-distribution-line[data-employee-id='#{ source_position_first.employees.third.id }']") do
              expect(page).to have_css ".cc-out", text: "204.25"
              expect(page).to have_css ".cash-out", text: "18.38"
              expect(page).to have_css ".tip-outs-given-cc", text: "20.42"
              expect(page).to have_css ".tip-outs-given-cash", text: "1.84"
              expect(page).to have_css ".tip-outs-received-cc", text: "0.41"
              expect(page).to have_css ".tip-outs-received-cash", text: "0.27"
              expect(page).to have_css ".final-tips-distributed-cc", text: "184.23"
              expect(page).to have_css ".final-tips-distributed-cash", text: "16.82"
            end

            within("table[id='#{ source_position_first.name }-1'] .info") do
              expect(page).to have_css ".total-cc-out", text: "551.47"
              expect(page).to have_css ".total-cash-out", text: "49.63"
              expect(page).to have_css ".total-tip-outs-given-cc", text: "55.15"
              expect(page).to have_css ".total-tip-outs-given-cash", text: "4.96"
              expect(page).to have_css ".total-tip-outs-received-cc", text: "1.10"
              expect(page).to have_css ".total-tip-outs-received-cash", text: "0.74"
              expect(page).to have_css ".total-tips-distributed-cc", text: "497.426"
              expect(page).to have_css ".total-tips-distributed-cash", text: "45.40"
            end
          end

          scenario "should have right employee calculations for non source position #1" do
            within(".employee-distribution-line[data-employee-id='#{ source_position_second.employees.first.id }']") do
              expect(page).to have_css ".cc-out", text: "117.65"
              expect(page).to have_css ".cash-out", text: "10.59"
              expect(page).to have_css ".tip-outs-given-cc", text: "11.76"
              expect(page).to have_css ".tip-outs-given-cash", text: "1.06"
              expect(page).to have_css ".tip-outs-received-cc", text: "0.24"
              expect(page).to have_css ".tip-outs-received-cash", text: "0.16"
              expect(page).to have_css ".final-tips-distributed-cc", text: "106.12"
              expect(page).to have_css ".final-tips-distributed-cash", text: "9.69"
            end
            within(".employee-distribution-line[data-employee-id='#{ source_position_second.employees.second.id }']") do
              expect(page).to have_css ".cc-out", text: "132.35"
              expect(page).to have_css ".cash-out", text: "11.91"
              expect(page).to have_css ".tip-outs-given-cc", text: "13.24"
              expect(page).to have_css ".tip-outs-given-cash", text: "1.19"
              expect(page).to have_css ".tip-outs-received-cc", text: "0.26"
              expect(page).to have_css ".tip-outs-received-cash", text: "0.18"
              expect(page).to have_css ".final-tips-distributed-cc", text: "119.38"
              expect(page).to have_css ".final-tips-distributed-cash", text: "10.90"
            end
            within(".employee-distribution-line[data-employee-id='#{ source_position_second.employees.third.id }']") do
              expect(page).to have_css ".cc-out", text: "147.06"
              expect(page).to have_css ".cash-out", text: "13.24"
              expect(page).to have_css ".tip-outs-given-cc", text: "14.71"
              expect(page).to have_css ".tip-outs-given-cash", text: "1.32"
              expect(page).to have_css ".tip-outs-received-cc", text: "0.29"
              expect(page).to have_css ".tip-outs-received-cash", text: "0.20"
              expect(page).to have_css ".final-tips-distributed-cc", text: "132.65"
              expect(page).to have_css ".final-tips-distributed-cash", text: "12.11"
            end

            within("table[id='#{ source_position_second.name }-1'] .info") do
              expect(page).to have_css ".total-cc-out", text: "397.06"
              expect(page).to have_css ".total-cash-out", text: "35.74"
              expect(page).to have_css ".total-tip-outs-given-cc", text: "39.71"
              expect(page).to have_css ".total-tip-outs-given-cash", text: "3.57"
              expect(page).to have_css ".total-tip-outs-received-cc", text: "0.79"
              expect(page).to have_css ".total-tip-outs-received-cash", text: "0.53"
              expect(page).to have_css ".total-tips-distributed-cc", text: "358.147"
              expect(page).to have_css ".total-tips-distributed-cash", text: "32.69"
            end
          end

          scenario "should have right employee calculations for non source position #1" do
            within(".employee-distribution-line[data-employee-id='#{ not_source_position_first.employees.first.id }']") do
              expect(page).to have_css ".cc-out", text: "163.40"
              expect(page).to have_css ".cash-out", text: "14.71"
              expect(page).to have_css ".tip-outs-given-cc", text: "16.34"
              expect(page).to have_css ".tip-outs-given-cash", text: "1.47"
              expect(page).to have_css ".tip-outs-received-cc", text: "0.33"
              expect(page).to have_css ".tip-outs-received-cash", text: "0.22"
              expect(page).to have_css ".final-tips-distributed-cc", text: "147.39"
              expect(page).to have_css ".final-tips-distributed-cash", text: "13.45"
            end
            within(".employee-distribution-line[data-employee-id='#{ not_source_position_first.employees.second.id }']") do
              expect(page).to have_css ".cc-out", text: "183.82"
              expect(page).to have_css ".cash-out", text: "16.54"
              expect(page).to have_css ".tip-outs-given-cc", text: "18.38"
              expect(page).to have_css ".tip-outs-given-cash", text: "1.65"
              expect(page).to have_css ".tip-outs-received-cc", text: "0.37"
              expect(page).to have_css ".tip-outs-received-cash", text: "0.25"
              expect(page).to have_css ".final-tips-distributed-cc", text: "165.81"
              expect(page).to have_css ".final-tips-distributed-cash", text: "15.13"
            end
            within(".employee-distribution-line[data-employee-id='#{ not_source_position_first.employees.third.id }']") do
              expect(page).to have_css ".cc-out", text: "204.25"
              expect(page).to have_css ".cash-out", text: "18.38"
              expect(page).to have_css ".tip-outs-given-cc", text: "20.42"
              expect(page).to have_css ".tip-outs-given-cash", text: "1.84"
              expect(page).to have_css ".tip-outs-received-cc", text: "0.41"
              expect(page).to have_css ".tip-outs-received-cash", text: "0.27"
              expect(page).to have_css ".final-tips-distributed-cc", text: "184.23"
              expect(page).to have_css ".final-tips-distributed-cash", text: "16.82"
            end

            within("table[id='#{ not_source_position_first.name }-1'] .info") do
              expect(page).to have_css ".total-cc-out", text: "551.47"
              expect(page).to have_css ".total-cash-out", text: "49.63"
              expect(page).to have_css ".total-tip-outs-given-cc", text: "55.15"
              expect(page).to have_css ".total-tip-outs-given-cash", text: "4.96"
              expect(page).to have_css ".total-tip-outs-received-cc", text: "1.10"
              expect(page).to have_css ".total-tip-outs-received-cash", text: "0.74"
              expect(page).to have_css ".total-tips-distributed-cc", text: "497.426"
              expect(page).to have_css ".total-tips-distributed-cash", text: "45.40"
            end
          end
        end
      end

      xfeature "2 teams" do
      end
    end

    xfeature "INTEGRATED: point calculations" do
    end
  end
end