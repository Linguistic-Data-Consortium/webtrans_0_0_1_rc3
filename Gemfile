source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


ruby '3.0.3'

# gem 'sprockets', '3.7.2' # strange manifest bug occurs with v4.0.0

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '7.0.0'
gem "sprockets-rails"
# Use sqlite3 as the database for Active Record
# Use Puma as the app server
gem 'puma'

gem 'vite_rails'

# Use SCSS for stylesheets
gem "autoprefixer-rails", '~> 6.5.1'
gem 'bourbon', '7.0.0'
gem 'neat', '1.7.4'
gem 'le', '2.2.6'
# gem 'sassc'
# gem 'sassc-rails'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
# gem 'coffee-rails', '5.0.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '2.10.0'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'haml', '5.1.2'
gem 'jquery-rails-cdn', '1.1.2'
gem 'jquery-datatables-rails'

gem 'paper_trail', '12.2.0'
# gem 'paper_trail-association_tracking'
gem 'carrierwave', '~> 1.0'

gem "aws-sdk-rails", '~> 3'
gem "aws-sdk-s3", '~> 1'
gem "aws-sdk-cognitoidentity", "~> 1.31"

# for project pagination
gem 'kaminari'

gem 'redcarpet'
gem 'rouge'

# gem 'thredded', '0.16.16'

gem 'sequel'

gem 'pg', '1.2.3'
gem "recaptcha"
gem 'mini_magick'
gem 'image_processing', '~> 1.2'

gem 'sqlite3'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'pry-rails'
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'shoulda-matchers', '4.0.0.rc1'
  gem 'rails-controller-testing' # If you are using Rails 5.x
  gem 'factory_bot_rails'
  gem 'database_cleaner'
end

gem "tailwindcss-rails", '2.0.5'
gem "bootsnap", require: false
gem 'faker', '2.20.0'
