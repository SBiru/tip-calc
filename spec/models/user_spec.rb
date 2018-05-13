require "rails_helper"

describe User do
  let!(:user) { FactoryGirl.create(:user) }

  it "should create user and restaurant" do
    expect(user.restaurant).not_to eq(nil)
  end
end