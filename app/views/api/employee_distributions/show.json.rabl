object @employee_distribution

attributes :status,  :hours_worked, :team_number, :cash_tips, :cc_tips, :sales_summ

node do |employee_distribution|
  {
    id: employee_distribution.id.to_s,
    date: employee_distribution.date.strftime("%m/%d/%y"),
    employee_id: employee_distribution.employee_id.to_s,
    position_type_id: employee_distribution.position_type_id.to_s,
    position_type_name: employee_distribution.position_type.name,
    employee_name: employee_distribution.employee.integrated_info,
  }
end



