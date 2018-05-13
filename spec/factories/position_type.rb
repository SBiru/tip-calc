FactoryGirl.define do
  sequence :position_name do |n|
    positions = %w{ server runner bartender stocker manager}
    "#{ positions[n%positions.count] }-team-##{ n }"
  end

  factory :position_type do
    name { generate(:position_name) }

    factory :position_type_with_employees, class: PositionType do
      after(:create) do |position_type|
        3.times { FactoryGirl.create(:employee, position_types: [position_type], restaurant: position_type.restaurant) }
      end
    end
  end
end
