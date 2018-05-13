FactoryGirl.define do
  factory :restaurant do
    name "High Kitchen"

    factory :seeded_restaurant, class: Restaurant do
      after(:create) do |restaurant|
        3.times { FactoryGirl.create(:area_type, restaurant: restaurant) }
        3.times { FactoryGirl.create(:shift_type, restaurant: restaurant) }
        3.times { FactoryGirl.create(:position_type_with_employees, restaurant: restaurant) }

        AreaShift.all.each do |f|
          f.days = AreaShift::DAYS
          f.position_types = restaurant.position_types
          f.save;
        end
        restaurant.reload
      end
    end
  end
end
