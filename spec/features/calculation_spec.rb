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
      distribution_type: "percents"
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
    let!(:not_source_position) { restaurant.position_types.last }

    before :each do
      visit show_calculation_get_path(calculation_id: calculation.id.to_s)
    end

    scenario "should pass right gon params", js: true do
      expect(js("gon.calculation_id")).to eq(calculation.id.to_s)
    end

    scenario "should add employees" do
      within("#distributions-list") do
        expect(page).not_to have_css "table[data-position-table='#{ source_position.name }'] tbody tr.employee-distribution-line"
        find("[data-action='add-employee'][data-position='#{ source_position.name }']").click
        expect(page).to have_css "table[data-position-table='#{ source_position.name }'] tbody tr.employee-distribution-line"
      end
    end

    feature "updating percantage table total" do
      feature "percents" do
        scenario "should count total percents - correct value" do
          within("#percentage #positions-table") do
            find(:css, ".total-position-tips[data-position-type='#{ source_position.name }'] .percentage-point").set '75'
            find(:css, ".total-position-tips[data-position-type='#{ not_source_position.name }'] .percentage-point").set '25'
            expect(page).to have_css "span.percentage-total", text: "100"
          end
        end

        scenario "should count total percents - incorrect value" do
          within("#percentage #positions-table") do
            find(:css, ".total-position-tips[data-position-type='#{ source_position.name }'] .percentage-point").set '75'
            find(:css, ".total-position-tips[data-position-type='#{ not_source_position.name }'] .percentage-point").set '75'
            expect(page).to have_css ".percentage-total-cell.danger span.percentage-total", text: "150"
          end
        end
      end
    end
  end
end
