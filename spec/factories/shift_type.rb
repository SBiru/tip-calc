FactoryGirl.define do
  sequence :shift_name do |n|
    shifts = %w{ breakfast dinner supper brunch lunch }

    "#{ shifts[n%shifts.count] } ##{ n }"
  end

  factory :shift_type do
    name { generate(:shift_name) }
  end
end
