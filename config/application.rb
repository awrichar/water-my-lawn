require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Workspace
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set local environment variables from a file /config/local_env.yml
    # See http://railsapps.github.com/rails-environment-variables.html
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      YAML.load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
      end if File.exists?(env_file)
    end

    # Configure Google API key for geocoding
    Geokit::Geocoders::GoogleGeocoder.api_key = ENV["GOOGLE_API_KEY"]

    # Configure Google API key for timezones
    Timezone::Configure.begin do |c|
      c.google_api_key = ENV["GOOGLE_API_KEY"]
    end
  end
end
