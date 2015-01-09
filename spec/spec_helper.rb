require 'rack/test'
require 'rspec'

require 'graphfinder_wrapper'
require 'graphfinder_wrapper_ws'

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app() GraphFinderWrapperWS end
end

# For RSpec 2.x
RSpec.configure { |c| c.include RSpecMixin }
