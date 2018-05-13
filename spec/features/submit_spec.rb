require 'capybara/rspec'
require 'spec_helper'

feature 'Employee submit tips' do
  let!(:restaurant) { FactoryGirl.create(:seeded_restaurant, user: FactoryGirl.create(:user)) }

  feature "successfull submit" do
    before :each do
      fill_submit_form
      click_on 'Submit'
    end
    scenario "employee should see flash message" do
      expect(page).to have_content 'Thank you for submitting your Tips'
    end

    scenario "should create distribution" do
      expect(restaurant.employee_distributions.pending.count).to eq(1)
    end

    scenario "should create calculation" do
      expect(restaurant.calculations.count).to eq(1)
    end

    scenario "should link calculation and distribution" do
      calculation = restaurant.calculations.first
      ed = restaurant.employee_distributions.pending.first
      expect(calculation.pending_distributions.include?(ed)).to eq(true)
    end
  end

  feature "unsuccessfull submit" do
    scenario "approved employee distribution already exists" do
      fill_submit_form
      click_on 'Submit'
      EmployeeDistribution.unscoped.first.approve!(restaurant.calculations.first)
      fill_submit_form
      click_on 'Submit'
      expect(page).to have_content 'Please see manager for more information.'
    end
  end

  feature "unsuccessfull submit" do
    scenario "pending employee distribution already exists" do
      fill_submit_form
      click_on 'Submit'
      expect(restaurant.employee_distributions.pending.count).to eq(1)
      fill_submit_form
      click_on 'Submit'
      expect(restaurant.employee_distributions.pending.count).to eq(1)
      expect(page).to have_content 'Please see manager for more information.'
    end
  end

  feature "should not duplicate calculation after submit" do
    scenario "should be 1 calculation" do
      fill_submit_form
      click_on 'Submit'
      expect(Calculation.count).to eq(1)

      fill_submit_form
      click_on 'Submit'
      expect(Calculation.count).to eq(1)
    end
  end

  feature "choosing previous date" do
    before :each do
      fill_submit_form
      select (Time.zone.now.to_date - 1.day).strftime("%m/%d/%y"), from: "employee_distribution_date"
      click_on 'Submit'
    end

    scenario "employee should see flash message" do
      expect(page).to have_content 'Thank you for submitting your Tips'
    end

    scenario "should create distribution" do
      expect(restaurant.employee_distributions.pending.count).to eq(1)
    end

    scenario "should create calculation" do
      expect(restaurant.calculations.count).to eq(1)
    end

    scenario "should link calculation and distribution" do
      calculation = restaurant.calculations.first
      expect(calculation.date).to eq(Time.zone.now.to_date  - 1.day)
    end
  end

  def fill_submit_form
    visit "/#{ restaurant.permalink }"
    
    fill_in 'employee_distribution_hours_worked', with: '10'
    fill_in 'employee_distribution_cash_tips', with: "20"
    fill_in 'employee_distribution_cc_tips', with: "20"
    select "1", from: "employee_distribution_team_number"
    select restaurant.area_types.first.name, from: "employee_distribution_area_type"
    select restaurant.shift_types.first.name, from: "employee_distribution_shift_type"
    select restaurant.position_types.first.name, from: "employee_distribution_position_type"
    select restaurant.employees.first.integrated_info, from: "employee_distribution_employee"
  end
end
