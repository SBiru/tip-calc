require 'capybara/rspec'
require 'spec_helper'

feature 'Frontend calculations' do
  include_context :gon
  let!(:restaurant) { FactoryGirl.create(:seeded_restaurant, user: FactoryGirl.create(:user)) }
  let!(:user) { restaurant.user }
  let!(:calculation) {
    FactoryGirl.create(:calculation,
      restaurant: restaurant.reload,
      user: restaurant.user,
      shift_type: restaurant.shift_types.first,
      area_type: restaurant.area_types.first,
      source_position_ids: [restaurant.position_types.first.id.to_s],
      distribution_type: "percents",
      teams_quantity: 2
    )
  }
  let!(:source_position) { restaurant.position_types.first }
  let!(:not_source_position_first) { restaurant.position_types.second }
  let!(:not_source_position_second) { restaurant.position_types.third }

  let!(:area_2) { restaurant.area_types.second }
  let!(:area_3) { restaurant.area_types.third }
  # let!(:sender_calculation) {
  #   FactoryGirl.create(:calculation,
  #     restaurant: restaurant.reload,
  #     user: restaurant.user,
  #     shift_type: restaurant.shift_types.first,
  #     area_type: restaurant.area_types.last,
  #     source_position_ids: [restaurant.position_types.first.id.to_s],
  #     distribution_type: "percents"
  #   )
  # }

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

    visit show_calculation_get_path(calculation_id: calculation.id.to_s)
  end
  
  feature "2 teams percent calculations", js: true do
    feature "3 source employees (2 teams) + 2 nonsource employees" do
      before :each do
        within("#percentage #positions-table") do
          find(:css, ".total-position-tips[data-position-type='#{ source_position.name }'] .percentage-point").set '50'
          find(:css, ".total-position-tips[data-position-type='#{ not_source_position_first.name }'] .percentage-point").set '30'
          find(:css, ".total-position-tips[data-position-type='#{ not_source_position_second.name }'] .percentage-point").set '20'
        end

        # SOURCE POSITIONS

        # Add 3 source employees for team 1
        within("#distributions-list") do
          find("[data-action='add-employee'][data-team='1'][data-position='#{ source_position.name }']").click
          find("[data-action='add-employee'][data-team='1'][data-position='#{ source_position.name }']").click

          # Fill collected money
          within("table[id='#{source_position.name}-1']") do
            within(".employee-distribution-line[data-employee-id='#{ source_position.employees.first.id }']") do
              find(:css, ".number-hrs").set '2.5'
              find(:css, ".cc-in input").set '100'
              find(:css, ".cash-in input").set '0'
            end
            within(".employee-distribution-line[data-employee-id='#{ source_position.employees.second.id }']") do
              find(:css, ".number-hrs").set '7.5'
              find(:css, ".cc-in input").set '0'
              find(:css, ".cash-in input").set '10'
            end
          end
        end

        # Add 3 source employees for team 2
        within("#distributions-list") do
          find("[data-action='add-employee'][data-team='2'][data-position='#{ source_position.name }']").click

          # Fill collected money
          within("table[id='#{source_position.name}-2']") do
            within(".employee-distribution-line[data-employee-id='#{ source_position.employees.first.id }']") do
              find(:css, ".number-hrs").set '10'
              find(:css, ".cc-in input").set '200'
              find(:css, ".cash-in input").set '20'
            end
          end
        end

        # NON-SOURCE POSITIONS

        # Add 1 non-source employee
        within("#distributions-list") do
          find("[data-action='add-employee'][data-position='#{ not_source_position_first.name }']").click
          find("[data-action='add-employee'][data-position='#{ not_source_position_second.name }']").click

          within(".employee-distribution-line[data-employee-id='#{ not_source_position_first.employees.first.id }']") do
            find(:css, ".number-hrs").set '10'
          end

          within(".employee-distribution-line[data-employee-id='#{ not_source_position_second.employees.first.id }']") do
            find(:css, ".number-hrs").set '10'
          end
        end

        # TIP OUTS

        within(".percentage-block") do
          find("a[href='#tip-out']").click
        end

        # Add tip out to 1 area

        # find("#tip-out.active [data-action='add-area']").click
        # find("#tip-out.active [data-action='add-area']").click

        # all(".tip-out-line .area-type-select-wrapper .select2-container").first.click
        # find(".select2-results__option", text: area_2.name.titleize).click
        # all(".tip-out-line .tip-out-percentage").first.set 5

        # all(".tip-out-line .area-type-select-wrapper .select2-container").last.click
        # find(".select2-results__option", text: area_3.name.titleize).click
        # all(".tip-out-line .tip-out-percentage").last.set 15

        # Show tip outs
        find(".toggle-tip-outs-wrapper .iCheck-helper").click
      end

      # scenario "should have received tip outs" do
      #   within(".percentage-block") do
      #     within("#received-tipouts-table .received-tip-out-line[data-area-name='#{ tip_out_received.sender.name }']") do
      #       expect(page).to have_css ".cc-received", text: "100"
      #       expect(page).to have_css ".cash-received", text: "80"
      #     end
      #   end
      # end

      # scenario "should have given tip outs" do
      #   within(".percentage-block") do
      #     find("a[href='#tip-out']").click

      #     within("#given-tipouts-table") do
      #       within all(".tip-out-line").last do
      #       # within(".tip-out-line[data-area-name='#{ area_2.name }']") do
      #         expect(page).to have_css ".cc_summ", text: "90"
      #         expect(page).to have_css ".cash_summ", text: "9"
      #       end

      #       within all(".tip-out-line").first do
      #       # within(".tip-out-line[data-area-name='#{ area_3.name }']") do
      #         expect(page).to have_css ".cc_summ", text: "30"
      #         expect(page).to have_css ".cash_summ", text: "3"
      #       end
      #     end
      #   end
      # end

      scenario "should have right totals table" do
        within("#total-block") do
          expect(page).to have_css ".cc-out-total", text: '300'
          expect(page).to have_css ".cash-out-total", text: '30'
          expect(page).to have_css ".tip-outs-given-cc", text: '0'
          expect(page).to have_css ".tip-outs-given-cash", text: '0'
          expect(page).to have_css ".tip-outs-received-cc", text: '0'
          expect(page).to have_css ".tip-outs-received-cash", text: '0'
          expect(page).to have_css ".tips-distributed-cc", text: '300'
          expect(page).to have_css ".tips-distributed-cash", text: '30'
          expect(page).to have_css ".tips-to-distribute-cc", text: '300'
          expect(page).to have_css ".tips-to-distribute-cash", text: '30'
          expect(page).to have_css ".hours", text: '40'
        end
      end

      scenario "should have right percentage table numbers" do
        find("a[href='#percentage']").click

        within("#percentage #positions-table") do
          within ".total-position-tips[data-position-type='#{ source_position.name }']" do
            expect(page).to have_css ".total-position-cc-tips", text: "150" 
            expect(page).to have_css ".total-position-cash-tips", text: "15" 
          end
          within ".total-position-tips[data-position-type='#{ not_source_position_first.name }']" do
            expect(page).to have_css ".total-position-cc-tips", text: "90" 
            expect(page).to have_css ".total-position-cash-tips", text: "9" 
          end
          within ".total-position-tips[data-position-type='#{ not_source_position_second.name }']" do
            expect(page).to have_css ".total-position-cc-tips", text: "60"
            expect(page).to have_css ".total-position-cash-tips", text: "6" 
          end

          expect(page).to have_css ".total-tip-out-summ .percentage-point span", text: '0'
          expect(page).to have_css ".total-tip-out-summ .total-tip-out-cc-tips", text: '0'
          expect(page).to have_css ".total-tip-out-summ .total-tip-out-cash-tips", text: '0'

          expect(page).to have_css ".total .percentage-total", text: '100'
          expect(page).to have_css ".total .total-collected-cc-tips", text: '300'
          expect(page).to have_css ".total .total-collected-cash-tips", text: '30'
        end
      end

      scenario "should have right employee calculations for source positions" do
        within "table[id='#{source_position.name}-1']" do
          within(".employee-distribution-line[data-employee-id='#{ source_position.employees.first.id }']") do
            expect(page).to have_css ".cc-out", text: '12.5'
            expect(page).to have_css ".cash-out", text: '1.25'
            expect(page).to have_css ".tip-outs-given-cc", text: '0'
            expect(page).to have_css ".tip-outs-given-cash", text: '0'
            expect(page).to have_css ".tip-outs-received-cc", text: '0'
            expect(page).to have_css ".tip-outs-received-cash", text: '0'
            expect(page).to have_css ".final-tips-distributed-cc", text: '12.5'
            expect(page).to have_css ".final-tips-distributed-cash", text: '1.25'
          end
          within(".employee-distribution-line[data-employee-id='#{ source_position.employees.second.id }']") do
            expect(page).to have_css ".cc-out", text: '37.5'
            expect(page).to have_css ".cash-out", text: '3.75'
            expect(page).to have_css ".tip-outs-given-cc", text: '0'
            expect(page).to have_css ".tip-outs-given-cash", text: '0'
            expect(page).to have_css ".tip-outs-received-cc", text: '0'
            expect(page).to have_css ".tip-outs-received-cash", text: '0'
            expect(page).to have_css ".final-tips-distributed-cc", text: '37.5'
            expect(page).to have_css ".final-tips-distributed-cash", text: '3.75'
          end

          within(".info") do
            expect(page).to have_css ".total-cc-out", text: '50'
            expect(page).to have_css ".total-cash-out", text: '5'
            expect(page).to have_css ".total-tip-outs-given-cc", text: '0'
            expect(page).to have_css ".total-tip-outs-given-cash", text: '0'
            expect(page).to have_css ".total-tip-outs-received-cc", text: '0'
            expect(page).to have_css ".total-tip-outs-received-cash", text: '0'
            expect(page).to have_css ".total-tips-distributed-cc", text: '50'
            expect(page).to have_css ".total-tips-distributed-cash", text: '5'
          end
        end
      end

      scenario "should have right employee calculations for source positions" do
        within "table[id='#{source_position.name}-2']" do
          within(".employee-distribution-line[data-employee-id='#{ source_position.employees.first.id }']") do
            expect(page).to have_css ".cc-out", text: '100'
            expect(page).to have_css ".cash-out", text: '10'
            expect(page).to have_css ".tip-outs-given-cc", text: '0'
            expect(page).to have_css ".tip-outs-given-cash", text: '0'
            expect(page).to have_css ".tip-outs-received-cc", text: '0'
            expect(page).to have_css ".tip-outs-received-cash", text: '0'
            expect(page).to have_css ".final-tips-distributed-cc", text: '100'
            expect(page).to have_css ".final-tips-distributed-cash", text: '10'
          end

          within(".info") do
            expect(page).to have_css ".total-cc-out", text: '100'
            expect(page).to have_css ".total-cash-out", text: '10'
            expect(page).to have_css ".total-tip-outs-given-cc", text: '0'
            expect(page).to have_css ".total-tip-outs-given-cash", text: '0'
            expect(page).to have_css ".total-tip-outs-received-cc", text: '0'
            expect(page).to have_css ".total-tip-outs-received-cash", text: '0'
            expect(page).to have_css ".total-tips-distributed-cc", text: '100'
            expect(page).to have_css ".total-tips-distributed-cash", text: '10'
          end
        end
      end

      scenario "should have right employee calculations for non source position #1" do
        within "table[id='#{not_source_position_first.name}-1']" do
          within(".employee-distribution-line[data-employee-id='#{ not_source_position_first.employees.first.id }']") do
            expect(page).to have_css ".cc-out", text: '90'
            expect(page).to have_css ".cash-out", text: '9'
            expect(page).to have_css ".tip-outs-given-cc", text: '0'
            expect(page).to have_css ".tip-outs-given-cash", text: '0'
            expect(page).to have_css ".tip-outs-received-cc", text: '0'
            expect(page).to have_css ".tip-outs-received-cash", text: '0'
            expect(page).to have_css ".final-tips-distributed-cc", text: '90'
            expect(page).to have_css ".final-tips-distributed-cash", text: '9'
          end

          within(".info") do
            expect(page).to have_css ".total-cc-out", text: '90'
            expect(page).to have_css ".total-cash-out", text: '9'
            expect(page).to have_css ".total-tip-outs-given-cc", text: '0'
            expect(page).to have_css ".total-tip-outs-given-cash", text: '0'
            expect(page).to have_css ".total-tip-outs-received-cc", text: '0'
            expect(page).to have_css ".total-tip-outs-received-cash", text: '0'
            expect(page).to have_css ".total-tips-distributed-cc", text: '90'
            expect(page).to have_css ".total-tips-distributed-cash", text: '9'
          end
        end
      end

      scenario "should have right employee calculations for non source position #1" do
        within "table[id='#{not_source_position_second.name}-1']" do
          within(".employee-distribution-line[data-employee-id='#{ not_source_position_second.employees.first.id }']") do
            expect(page).to have_css ".cc-out", text: '60'
            expect(page).to have_css ".cash-out", text: '6'
            expect(page).to have_css ".tip-outs-given-cc", text: '0'
            expect(page).to have_css ".tip-outs-given-cash", text: '0'
            expect(page).to have_css ".tip-outs-received-cc", text: '0'
            expect(page).to have_css ".tip-outs-received-cash", text: '0'
            expect(page).to have_css ".final-tips-distributed-cc", text: '60'
            expect(page).to have_css ".final-tips-distributed-cash", text: '6'
          end

          within(".info") do
            expect(page).to have_css ".total-cc-out", text: '60'
            expect(page).to have_css ".total-cash-out", text: '6'
            expect(page).to have_css ".total-tip-outs-given-cc", text: '0'
            expect(page).to have_css ".total-tip-outs-given-cash", text: '0'
            expect(page).to have_css ".total-tip-outs-received-cc", text: '0'
            expect(page).to have_css ".total-tip-outs-received-cash", text: '0'
            expect(page).to have_css ".total-tips-distributed-cc", text: '60'
            expect(page).to have_css ".total-tips-distributed-cash", text: '6'
          end
        end
      end
    end
  end
end