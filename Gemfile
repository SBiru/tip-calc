source 'http://rubygems.org'

gem 'rails', '4.2.4'
gem 'mongoid', '~> 4.0.0'
gem 'bson_ext'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'
gem 'turbolinks'
gem 'jbuilder', '~> 2.0'
gem 'sdoc', '~> 0.4.0', group: :doc
gem "figaro"
gem "select2-rails"
gem 'gon'
gem 'rabl'
# gem 'rabl-rails'
gem 'oj'
gem 'awesome_print', require: "ap"
gem 'jquery-datatables-rails', '~> 3.4.0'
gem 'stripe', :git => 'https://github.com/stripe/stripe-ruby'

#styles
gem 'browser'
gem 'font-awesome-rails'
# gem 'autoprefixer-rails'
gem 'non-stupid-digest-assets'

gem 'devise'
gem 'mongoid-sequencer'
gem 'rollbar'
gem 'mailgun_rails'
gem 'axlsx_rails'
gem 'dropbox-sdk'
gem 'mongoid-history'

group :assets do
  gem 'eco'
end

group :development do
  gem 'capistrano', '~> 3.4.0'
  gem 'capistrano-rails'
  gem 'capistrano-bundler'
  gem 'capistrano-rvm'
  gem 'capistrano-figaro-yml'
  gem 'pry-byebug'
  gem "better_errors"
  gem "binding_of_caller"
  # gem 'quiet_assets'
end

group :production do
  gem 'unicorn'
end

group :test do
  gem 'rspec-rails', '~> 3.0.1'
  gem 'mongoid-rspec', '~> 2.0.0.rc1'
  gem 'factory_girl_rails', :require => false
  gem 'capybara'
  gem "capybara-webkit"
  gem 'database_cleaner'
  gem 'timecop'
  gem 'launchy'
end

gem 'parallel_tests', group: [:development, :test]