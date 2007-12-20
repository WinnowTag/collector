# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# DWS - In our configuration, when running behind Apache, RAILS_ROOT
#       is incorrectly set to /comm/pwo/www.peerworks.org. The following
#       lines pull in a definition for RAILS_ROOT from an environment
#       variable that may be set in the Apache configuration file. If
#       running under WEBrick RAILS_ROOT will have been already defined,
#       and no action is taken.
#
# As yet unknown whether needed in non-IMS configuration.
#
# if !defined? RAILS_ROOT
#   RAILS_ROOT = ENV['RAILS_ROOT']
# end
# load any host specific configuration
RAILS_GEM_VERSION = "2.0.1"
host_specific_config = File.join(File.dirname(__FILE__), 'local', 'environment.rb')
if File.exist?(host_specific_config)
  require host_specific_config
end

AUTHORIZATION_MIXIN = 'object roles'
STORE_LOCATION_METHOD = :store_location

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
ENV['INLINEDIR'] = File.join(RAILS_ROOT, '.ruby_inline')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :info

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  config.active_record.schema_format = :sql

  # Activate observers that should always be running
  #config.active_record.observers = :user_observer

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
end
