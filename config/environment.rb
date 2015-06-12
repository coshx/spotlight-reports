# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

# LTI requirements
require 'oauth/request_proxy/rack_request'
OAUTH_10_SUPPORT = true
