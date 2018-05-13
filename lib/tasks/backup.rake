desc "backing up to dropbox account with hello@tipmetric.com email"
task :backup_to_dropbox => :environment do
  require 'dropbox_sdk'

  folder_name = Rails.env.production? ? "/home/deployer/projects/tipcalc/shared" : Rails.root.join("tmp")
  file_name = Time.now.strftime("%Y_%m_%d-%H_%M_%S") + ".#{ Rails.env }"

  archive_path = "#{folder_name}/#{ file_name }.tar.gz"
  folder_path = "#{folder_name}/#{ file_name }"

  command_line = if Rails.env.production?
    system "mongodump --host 127.0.0.1:27017 --db tipcalc_production --username tipcalc_db_user --password tipcalc_db_password --out #{ folder_path }"
  else
    system "mongodump --host 127.0.0.1:27017 --db tipcalc_development --out #{ folder_path }"
  end

  system("tar -zcvpf #{ archive_path } #{ folder_path }")

  client = DropboxClient.new(ENV["dropbox_api"])
  # puts "linked account:", client.account_info().inspect

  puts archive_path

  file = open(archive_path)
  response = client.put_file("#{ file_name }.tar.gz", file)
  # puts "uploaded:", response.inspect
end