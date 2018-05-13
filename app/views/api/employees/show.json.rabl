object @employee

attributes :first_name, :last_name, :emp_id, :active

node do |employee|
  {
    id: employee.id.to_s,
    position_types: employee.position_type_ids
  }
end