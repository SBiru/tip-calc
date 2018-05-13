require 'capybara/rspec'
require 'spec_helper'

Capybara.javascript_driver = :webkit

feature "editor events" do
  let!(:user) { FactoryGirl.create(:user) }

  before :each do
    sign_in_as user
  end

  scenario "used should be signed in" do
    expect(page).to have_content "Total collected tips for the last 2 weeks."
  end

  # scenario "user should see editor form", js: true do
  #   visit create_path
  #   expect(page).to have_content "Type Package"
  # end

  # scenario "a button should be visible after click", js: true do
  #   visit create_path
  #   expect{
  #     find("#paper_body_editor").click
  #   }.to change{ page.evaluate_script("document.getElementById('a-button').style.display").to_s }.from("").to("block")
  # end

  # scenario "should pass to a publishing paper loader", js: true do
  #   visit create_path
  #   page.evaluate_script("$('#paper_title_editor').html('Sample title')")
  #   page.evaluate_script("$('#paper_title').val('Sample title')")
  #   page.evaluate_script("$('#paper_body_editor').html('Sample body')")
  #   page.evaluate_script("$('#paper_body').val('Sample body')")
  #   page.find(".start_publishing_paper").trigger("click")
  #   click_on "Okay"
  #   find("a.active").click
  #   find("a#finalize.publish").click
  #   find("a#finalize.publish").click
  #   sleep 3
  #   wait_for_ajax
  #   expect(page).to have_content "Posting"
  # end

  # scenario "should create paper", js: false do
  #   visit create_path
  #   find(:css, "input#paper_title").set("10")
  #   find(:css, "input#paper_body").set("10")
  #   page.find("#paper_publish").click
  #   expect(Paper.count).to eq(1)
  # end
end

