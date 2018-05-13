FactoryGirl.define do
  sequence :area_name do |n|
    areas = %w{ bar patio dinningroom cafe vip }

    "#{ areas[n%areas.count] } ##{ n }"
  end

  factory :area_type do
    name { generate(:area_name) }
  end
end
