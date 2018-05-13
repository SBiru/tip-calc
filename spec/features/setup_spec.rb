require 'capybara/rspec'
require 'spec_helper'

Capybara.javascript_driver = :webkit

feature "editor events" do
  let!(:user) { FactoryGirl.create(:user) }

  before :each do
    sign_in_as user
  end

  scenario "can edit the restaurant name", js: true do
    visit setup_path

    expect{ 
      find("#change-restaurant-name").click
      js("$('#restaurant-name').val('johny restaurant')").to_s
      find("#save-restaurant-name").click
      wait_for_ajax
    }.to change{ user.reload.restaurant.name }.from("Default Name 0").to("johny restaurant")
  end

  scenario "should add area", js: true do
    visit setup_path

    expect{
      find("#area-type-add").click
    }.to change{ js("$('#area-types-table tbody tr').length") }.from(0).to(1)
  end
end

