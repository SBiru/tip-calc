# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w(
  icheck.min.js
  sparkline.index.js
  bootstrap.min.js
  jquery.slimscroll.min.js
  metisMenu.min.js
  underscore.js
  underscore.js
  bootstrap-datepicker.min.js
  select2.min.js
  icheck.min.js
  chart.min.js
  jquery.bootstrap-touchspin.min
  moment.min
  offline.js
  sweet-alert.min.js
  homer.js
  backbone/setup.js
  backbone/employee.js
  backbone/calculation.js
  backbone/reports.js
  toastr.min.js
  home.js
  home/smooth-scroll
  home/jquery.ajaxchimp.min
  home/functions
)
Rails.application.config.assets.precompile += %w(
  animate.min.css
  bootstrap.min.css
  bootstrap.min.css.map
  metisMenu.min.css
  green.css
  offline.default.css
  offline.messages.css
  sweet-alert.css
  jquery.bootstrap-touchspin.min.css
  toastr.min.css
  homerstyle.css
  home/animate.css
  home/preloader.css
  home/homestyle.css
  home/default-color.css
  home.css
)

Rails.application.config.assets.precompile += %w(
  home/*.png home/**/*.png home/**/*.jpg
)

Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'html')
Rails.application.config.assets.register_mime_type('text/html', '.html')
