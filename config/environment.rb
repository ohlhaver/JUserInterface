# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )
  config.gem( 'authlogic', :version => '2.1.3', :lib => 'authlogic' )
  config.gem( 'rubycas-client', :version => '2.1.0' )
  config.gem( 'httpclient', :version => '2.1.5.2' )
  config.gem( 'log4r', :version => '1.1.7')
  config.gem( 'hashie', :version => '0.2.0' )
  config.gem( 'rest-client', :version => '1.5.1', :lib => 'restclient')
  
  require 'casclient'
  require 'casclient/frameworks/rails/filter'

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end

JModelConfig = YAML.load_file( "#{RAILS_ROOT}/config/j_models.yml" )
load "#{JModelConfig[RAILS_ENV]['path']}/config/environment.rb"
# Dir["#{RAILS_ROOT}/app/models/*.rb"].each do |model_file|
#   load model_file
# end
I18n.reload!
CasServerConfig = YAML.load_file( "#{RAILS_ROOT}/config/cas_server.yml" )

cas_logger = Logger.new(RAILS_ROOT+'/log/cas.log')
cas_logger.level = ActiveRecord::Base.logger.level

CASClient::Frameworks::Rails::Filter.configure(
  :cas_base_url => CasServerConfig[RAILS_ENV]['cas_server'],
  :username_session_key => :cas_user,
  :extra_attributes_session_key => :cas_user_attrs,
  :logger => cas_logger,
  :authenticate_on_every_request => false # true will load cas server heavily
)

JWebApp = CasServerConfig[ RAILS_ENV ]['app_server'].freeze
JUserApp = CasServerConfig[ RAILS_ENV ]['service'].freeze

#price is in milli cents
GatewayTransaction.gateway = ClickAndBuyGateway.new( 
  :mode => :production,
  :premium_links => { 
    1 => { :url => "http://premium-6s4h07enj949cu.eu.clickandbuy.com/", :price => 500000, :currency => 'EUR' } 
  },
  :merchant_id => 24409753,
  :transaction_password => 'cy7dofit',
  :success_url => 'http://accounts.jurnalo.com/click_and_buy/confirm',
  :error_url => 'http://accounts.jurnalo.com/click_and_buy/error'
)

PaidByInvoice.plans = {  
  :power => { :id => 5814899, :price => 395000, :currency => 'EUR' }
}

require 'app/models/user' if RAILS_ENV == 'development' || RAILS_ENV == 'justus'
# For emails when upgrade and signup is done then the invoice send immediately
InvoiceNotifier.delivery_method = :smtp