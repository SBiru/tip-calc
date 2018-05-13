desc "Move 404 and 500 page to public folder"
task :move_error_pages => :environment do
  ["404", "500"].each do |error_code|
    file_name = error_code.concat(".html")
    command_line = "mv #{ Rails.root.join('public', 'assets', file_name)} #{ Rails.root.join('public', file_name)}"
    system(command_line)
  end
end