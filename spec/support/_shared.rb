FactoryGirl.define do
  sequence :email do |n|
    "user_#{n}@test.com"
  end
end
