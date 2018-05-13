FactoryGirl.define do
  sequence :first_name do |n|
    first_names = %w{ Karen Lucy Amanda Ricky Stanley John}
    "#{ first_names.sample }"
  end

  sequence :last_name do |n|
    last_names = %w{ A B C D E F}
    "#{ last_names.sample }"
  end

  sequence :emp_id do |n|
    "#{ n }"
  end

  factory :employee do
    first_name { generate(:first_name) }
    last_name { generate(:last_name) }
    emp_id { generate(:emp_id) }
  end
end
