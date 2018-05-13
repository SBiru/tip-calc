FactoryGirl.define do
  factory :user do
    email { generate(:email) }
    name "Test user"
    password "123123123"
  end
end
