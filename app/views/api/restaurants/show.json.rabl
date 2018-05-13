object @restaurant

attributes :id, :name

node do |restaurant|
  {
    current_date: restaurant.current_date
  }
end