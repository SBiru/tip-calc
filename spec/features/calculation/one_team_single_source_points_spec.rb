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
      source_position_ids: [restaurant.position_types.first.id.to_s],
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

    let!(:source_position) { restaurant.position_types.first }
    feature "INTEGRATED: percent calculations" do
      let!(:not_source_position_first) { restaurant.position_types.second }
      let!(:not_source_position_second) { restaurant.position_types.third }

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
              distribution_type: "points"
            )
          }

          let!(:tip_out_received) {TipOut.create(
            percentage: 20,
            cc_summ: 100,
            cash_summ: 80,
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
              find(:css, ".total-position-tips[data-position-type='#{ source_position.name }'] .percentage-point").set '4'
              find(:css, ".total-position-tips[data-position-type='#{ not_source_position_first.name }'] .percentage-point").set '2.5'
              find(:css, ".total-position-tips[data-position-type='#{ not_source_position_second.name }'] .percentage-point").set '1.5'
            end

            # SOURCE POSITIONS

            # Add 3 source employees
            within("#distributions-list") do
              find("[data-action='add-employee'][data-position='#{ source_position.name }']").click
              find("[data-action='add-employee'][data-position='#{ source_position.name }']").click
              find("[data-action='add-employee'][data-position='#{ source_position.name }']").click
            end
            
            # Fill collected money
            within(".employee-distribution-line[data-employee-id='#{ source_position.employees.first.id }']") do
              find(:css, ".number-hrs").set '8'
              find(:css, ".cc-in input").set '100'
              find(:css, ".cash-in input").set '10'
            end
            within(".employee-distribution-line[data-employee-id='#{ source_position.employees.second.id }']") do
              find(:css, ".number-hrs").set '9'
              find(:css, ".cc-in input").set '200'
              find(:css, ".cash-in input").set '20'
            end
            within(".employee-distribution-line[data-employee-id='#{ source_position.employees.third.id }']") do
              find(:css, ".number-hrs").set '10'
              find(:css, ".cc-in input").set '300'
              find(:css, ".cash-in input").set '30'
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

            # Add 1 non-source employee
            within("#distributions-list") do
              find("[data-action='add-employee'][data-position='#{ not_source_position_second.name }']").click
              find("[data-action='add-employee'][data-position='#{ not_source_position_second.name }']").click
              find("[data-action='add-employee'][data-position='#{ not_source_position_second.name }']").click
            end
            within(".employee-distribution-line[data-employee-id='#{ not_source_position_second.employees.first.id }']") do
              find(:css, ".number-hrs").set '8'
            end
            within(".employee-distribution-line[data-employee-id='#{ not_source_position_second.employees.second.id }']") do
              find(:css, ".number-hrs").set '9'
            end
            within(".employee-distribution-line[data-employee-id='#{ not_source_position_second.employees.third.id }']") do
              find(:css, ".number-hrs").set '10'
            end

            # TIP OUTS

            within(".percentage-block") do
              find("a[href='#tip-out']").click
            end

            # Add tip out to 1 area

            find("#tip-out.active [data-action='add-area']").click
            find("#tip-out.active [data-action='add-area']").click


            all(".tip-out-line .area-type-select-wrapper .select2-container").first.click
            find(".select2-results__option", text: area_3.name.titleize).click
            all(".tip-out-line .tip-out-percentage").first.set 5

            all(".tip-out-line .area-type-select-wrapper .select2-container").last.click
            find(".select2-results__option", text: area_2.name.titleize).click
            all(".tip-out-line .tip-out-percentage").last.set 15

            # Show tip outs
            find(".toggle-tip-outs-wrapper .iCheck-helper").click
          end

          scenario "should have received tip outs" do
            within(".percentage-block") do
              within("#received-tipouts-table .received-tip-out-line[data-area-name='#{ tip_out_received.sender.name }']") do
                expect(page).to have_css ".cc-received", text: "100"
                expect(page).to have_css ".cash-received", text: "80"
              end
            end
          end

          scenario "should have given tip outs" do
            within(".percentage-block") do
              find("a[href='#tip-out']").click

              within("#given-tipouts-table") do
                within all(".tip-out-line").last do
                # within(".tip-out-line[data-area-name='#{ area_2.name }']") do
                  expect(page).to have_css ".cc_summ", text: "90"
                  expect(page).to have_css ".cash_summ", text: "9"
                end

                within all(".tip-out-line").first do
                # within(".tip-out-line[data-area-name='#{ area_3.name }']") do
                  expect(page).to have_css ".cc_summ", text: "30"
                  expect(page).to have_css ".cash_summ", text: "3"
                end
              end
            end
          end

          scenario "should have right totals table" do
            within("#total-block") do
              expect(page).to have_css ".cc-out-total", text: '600'
              expect(page).to have_css ".cash-out-total", text: '60'
              expect(page).to have_css ".tip-outs-given-cc", text: '120'
              expect(page).to have_css ".tip-outs-given-cash", text: '12'
              expect(page).to have_css ".tip-outs-received-cc", text: '100'
              expect(page).to have_css ".tip-outs-received-cash", text: '80'
              expect(page).to have_css ".tips-distributed-cc", text: '580'
              expect(page).to have_css ".tips-distributed-cash", text: '128'
              expect(page).to have_css ".tips-to-distribute-cc", text: '580'
              expect(page).to have_css ".tips-to-distribute-cash", text: '128'
              expect(page).to have_css ".hours", text: '81'
            end
          end

          scenario "should have right percentage table numbers" do
            # within(".percentage-block") do
              find("a[href='#percentage']").click
            # end

            within("#percentage #positions-table") do
              within ".total-position-tips[data-position-type='#{ source_position.name }']" do
                expect(page).to have_css ".total-position-cc-tips", text: "240" 
                expect(page).to have_css ".total-position-cc-tips", text: "24" 
              end
              within ".total-position-tips[data-position-type='#{ not_source_position_first.name }']" do
                expect(page).to have_css ".total-position-cc-tips", text: "150" 
                expect(page).to have_css ".total-position-cc-tips", text: "15" 
              end
              within ".total-position-tips[data-position-type='#{ not_source_position_second.name }']" do
                expect(page).to have_css ".total-position-cc-tips", text: "90" 
                expect(page).to have_css ".total-position-cc-tips", text: "9" 
              end
              
              within ".total-position-tips[data-position-type='#{ not_source_position_second.name }']" do
                expect(page).to have_css ".total-position-cc-tips", text: "90" 
                expect(page).to have_css ".total-position-cc-tips", text: "9" 
              end

              expect(page).to have_css ".total-tip-out-summ .percentage-point span", text: '20'
              expect(page).to have_css ".total-tip-out-summ .total-tip-out-cc-tips", text: '120'
              expect(page).to have_css ".total-tip-out-summ .total-tip-out-cash-tips", text: '12'

              expect(page).to have_css ".total .percentage-total", text: '216'
              expect(page).to have_css ".total .total-collected-cc-tips", text: '600'
              expect(page).to have_css ".total .total-collected-cash-tips", text: '60'
            end
          end

          scenario "should have right employee calculations for source positions" do
            within(".employee-distribution-line[data-employee-id='#{ source_position.employees.first.id }']") do
              expect(page).to have_css ".cc-out", text: '88.89'
              expect(page).to have_css ".cash-out", text: '8.89'
              expect(page).to have_css ".tip-outs-given-cc", text: '17.78'
              expect(page).to have_css ".tip-outs-given-cash", text: '1.78'
              expect(page).to have_css ".tip-outs-received-cc", text: '14.81'
              expect(page).to have_css ".tip-outs-received-cash", text: '11.85'
              expect(page).to have_css ".final-tips-distributed-cc", text: '85.93'
              expect(page).to have_css ".final-tips-distributed-cash", text: '18.96'
            end
            within(".employee-distribution-line[data-employee-id='#{ source_position.employees.second.id }']") do
              expect(page).to have_css ".cc-out", text: '100'
              expect(page).to have_css ".cash-out", text: '10'
              expect(page).to have_css ".tip-outs-given-cc", text: '20'
              expect(page).to have_css ".tip-outs-given-cash", text: '2'
              expect(page).to have_css ".tip-outs-received-cc", text: '16.67'
              expect(page).to have_css ".tip-outs-received-cash", text: '13.33'
              expect(page).to have_css ".final-tips-distributed-cc", text: '96.67'
              expect(page).to have_css ".final-tips-distributed-cash", text: '21.33'
            end
            within(".employee-distribution-line[data-employee-id='#{ source_position.employees.third.id }']") do
              expect(page).to have_css ".cc-out", text: '111.11'
              expect(page).to have_css ".cash-out", text: '11.11'
              expect(page).to have_css ".tip-outs-given-cc", text: '22.22'
              expect(page).to have_css ".tip-outs-given-cash", text: '2.22'
              expect(page).to have_css ".tip-outs-received-cc", text: '18.52'
              expect(page).to have_css ".tip-outs-received-cash", text: '14.81'
              expect(page).to have_css ".final-tips-distributed-cc", text: '107.41'
              expect(page).to have_css ".final-tips-distributed-cash", text: '23.70'
            end

            within("table[id='#{ source_position.name }-1'] .info") do
              expect(page).to have_css ".total-cc-out", text: '300'
              expect(page).to have_css ".total-cash-out", text: '30'
              expect(page).to have_css ".total-tip-outs-given-cc", text: '60'
              expect(page).to have_css ".total-tip-outs-given-cash", text: '6'
              expect(page).to have_css ".total-tip-outs-received-cc", text: '50'
              expect(page).to have_css ".total-tip-outs-received-cash", text: '40'
              expect(page).to have_css ".total-tips-distributed-cc", text: '290'
              expect(page).to have_css ".total-tips-distributed-cash", text: '64'
            end
          end

          scenario "should have right employee calculations for non source position #1" do
            within(".employee-distribution-line[data-employee-id='#{ not_source_position_first.employees.first.id }']") do
              expect(page).to have_css ".cc-out", text: '55.56'
              expect(page).to have_css ".cash-out", text: '5.56'
              expect(page).to have_css ".tip-outs-given-cc", text: '11.11'
              expect(page).to have_css ".tip-outs-given-cash", text: '1.11'
              expect(page).to have_css ".tip-outs-received-cc", text: '9.26'
              expect(page).to have_css ".tip-outs-received-cash", text: '7.41'
              expect(page).to have_css ".final-tips-distributed-cc", text: '53.70'
              expect(page).to have_css ".final-tips-distributed-cash", text: '11.85'
            end
            within(".employee-distribution-line[data-employee-id='#{ not_source_position_first.employees.second.id }']") do
              expect(page).to have_css ".cc-out", text: '62.50'
              expect(page).to have_css ".cash-out", text: '6.25'
              expect(page).to have_css ".tip-outs-given-cc", text: '12.50'
              expect(page).to have_css ".tip-outs-given-cash", text: '1.25'
              expect(page).to have_css ".tip-outs-received-cc", text: '10.42'
              expect(page).to have_css ".tip-outs-received-cash", text: '8.33'
              expect(page).to have_css ".final-tips-distributed-cc", text: '60.42'
              expect(page).to have_css ".final-tips-distributed-cash", text: '13.33'
            end
            within(".employee-distribution-line[data-employee-id='#{ not_source_position_first.employees.third.id }']") do
              expect(page).to have_css ".cc-out", text: '69.44'
              expect(page).to have_css ".cash-out", text: '6.94'
              expect(page).to have_css ".tip-outs-given-cc", text: '13.89'
              expect(page).to have_css ".tip-outs-given-cash", text: '1.39'
              expect(page).to have_css ".tip-outs-received-cc", text: '11.57'
              expect(page).to have_css ".tip-outs-received-cash", text: '9.26'
              expect(page).to have_css ".final-tips-distributed-cc", text: '67.13'
              expect(page).to have_css ".final-tips-distributed-cash", text: '14.81'
            end

            within("table[id='#{ not_source_position_first.name }-1'] .info") do
              expect(page).to have_css ".total-cc-out", text: '187.50'
              expect(page).to have_css ".total-cash-out", text: '18.75'
              expect(page).to have_css ".total-tip-outs-given-cc", text: '37.50'
              expect(page).to have_css ".total-tip-outs-given-cash", text: '3.75'
              expect(page).to have_css ".total-tip-outs-received-cc", text: '31.25'
              expect(page).to have_css ".total-tip-outs-received-cash", text: '25.00'
              expect(page).to have_css ".total-tips-distributed-cc", text: '181.25'
              expect(page).to have_css ".total-tips-distributed-cash", text: '40.00'
            end
          end

          scenario "should have right employee calculations for non source position #1" do
            within(".employee-distribution-line[data-employee-id='#{ not_source_position_second.employees.first.id }']") do
              expect(page).to have_css ".cc-out", text: '33.33'
              expect(page).to have_css ".cash-out", text: '3.33'
              expect(page).to have_css ".tip-outs-given-cc", text: '6.67'
              expect(page).to have_css ".tip-outs-given-cash", text: '0.67'
              expect(page).to have_css ".tip-outs-received-cc", text: '5.56'
              expect(page).to have_css ".tip-outs-received-cash", text: '4.44'
              expect(page).to have_css ".final-tips-distributed-cc", text: '32.22'
              expect(page).to have_css ".final-tips-distributed-cash", text: '7.11'
            end
            within(".employee-distribution-line[data-employee-id='#{ not_source_position_second.employees.second.id }']") do
              expect(page).to have_css ".cc-out", text: '37.50'
              expect(page).to have_css ".cash-out", text: '3.75'
              expect(page).to have_css ".tip-outs-given-cc", text: '7.50'
              expect(page).to have_css ".tip-outs-given-cash", text: '0.75'
              expect(page).to have_css ".tip-outs-received-cc", text: '6.25'
              expect(page).to have_css ".tip-outs-received-cash", text: '5.00'
              expect(page).to have_css ".final-tips-distributed-cc", text: '36.25'
              expect(page).to have_css ".final-tips-distributed-cash", text: '8'
            end
            within(".employee-distribution-line[data-employee-id='#{ not_source_position_second.employees.third.id }']") do
              expect(page).to have_css ".cc-out", text: '41.67'
              expect(page).to have_css ".cash-out", text: '4.17'
              expect(page).to have_css ".tip-outs-given-cc", text: '8.33'
              expect(page).to have_css ".tip-outs-given-cash", text: '0.83'
              expect(page).to have_css ".tip-outs-received-cc", text: '6.94'
              expect(page).to have_css ".tip-outs-received-cash", text: '5.56'
              expect(page).to have_css ".final-tips-distributed-cc", text: '40.28'
              expect(page).to have_css ".final-tips-distributed-cash", text: '8.89'
            end

            within("table[id='#{ not_source_position_second.name }-1'] .info") do
              expect(page).to have_css ".total-cc-out", text: '112.50'
              expect(page).to have_css ".total-cash-out", text: '11.25'
              expect(page).to have_css ".total-tip-outs-given-cc", text: '22.50'
              expect(page).to have_css ".total-tip-outs-given-cash", text: '2.25'
              expect(page).to have_css ".total-tip-outs-received-cc", text: '18.75'
              expect(page).to have_css ".total-tip-outs-received-cash", text: '15'
              expect(page).to have_css ".total-tips-distributed-cc", text: '108.75'
              expect(page).to have_css ".total-tips-distributed-cash", text: '24'
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