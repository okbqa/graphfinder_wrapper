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
		graphfinder_url = "http://110.45.246.131:38400/queries"
		# graphfinder_url = "http://ws.lodqa.org:38502/queries"
		# graphfinder_url = "http://localhost:9292/queries"
    @graphfinder_ws = RestClient::Resource.new graphfinder_url, :headers => {:content_type => :json, :accept => :json}

		if request.body && request.content_type && request.content_type.downcase == 'application/json'
			body = request.body.read
			begin
				json_params = JSON.parse body unless body.empty?
			rescue => e
				@error_message = 'ill-formed JSON string'
			end
			params.merge!(json_params) unless json_params.nil?
		end


			# @params = JSON.parse request.body.read 
	end

	get '/' do
		erb :index
	end

	post '/queries' do
		begin
			raise ArgumentError, @error_message if @error_message
			raise ArgumentError, "template should be passed" unless params.has_key?("template")
			raise ArgumentError, "disambiguation should be passed" unless params.has_key?("disambiguation")
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
		# rescue => e
		# 	content_type :json
		# 	{message: e.message}.to_json
		end
	end

end
