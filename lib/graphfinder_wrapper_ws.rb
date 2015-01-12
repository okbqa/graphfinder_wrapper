#!/usr/bin/env ruby
require 'sinatra/base'
require 'rest_client'
require 'erb'
require 'graphfinder_wrapper'
require 'json'

class GraphFinderWrapperWS < Sinatra::Base
	configure do
		set :root, File.dirname(__FILE__).gsub(/lib/, '/')
		set :protection, :except => :frame_options
		set :server, 'thin'
	end

	before do
		graphfinder_url = "http://ws.lodqa.org:38502/queries"
		# graphfinder_url = "http://localhost:9292/queries"
    @graphfinder_ws = RestClient::Resource.new graphfinder_url, :headers => {:content_type => :json, :accept => :json}

		@params = JSON.parse request.body.read if request.body && request.content_type && request.content_type.downcase == 'application/json'
	end

	get '/' do
		erb :index
	end

	post '/queries' do
		template = params["template"]
		disambiguation = params["disambiguation"]

		apgp, frame = GraphFinder::okbqa_wrapper(template, disambiguation)
		data = {"apgp" => apgp, "frame" => frame}

		result = 
    @graphfinder_ws.post data.to_json do |response, request, result|
      case response.code
      when 200
        JSON.parse response
      else
      	raise "Something wrong"
      end
    end

		content_type :json
		result.map{|r| {query:r, score:0.5}}.to_json
	end

end
