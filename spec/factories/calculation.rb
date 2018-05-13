FactoryGirl.define do
  factory :calculation do |c|
    teams_quantity 1
    date Time.zone.now.to_date
  end
end
