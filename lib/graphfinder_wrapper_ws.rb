#!/usr/bin/env ruby
require 'sinatra/base'
require 'rest_client'
require 'erb'
require 'graphfinder_wrapper'
require 'json'
require 'pp'

class GraphFinderWrapperWS < Sinatra::Base
	configure do
		set :root, File.dirname(__FILE__).gsub(/lib/, '/')
		set :protection, :except => :frame_options
		set :server, 'thin'
	end

	before do
		graphfinder_url = "http://ws.okbqa.org:38400/queries"
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

<<<<<<< HEAD
			apgps, frame = GraphFinder::okbqa_wrapper(template, disambiguation)
=======
			apgp, frame = GraphFinder::okbqa_wrapper(template, disambiguation)
			data = {"apgp" => apgp, "frame" => frame}
			data["max_hop"] = params["max_hop"].to_i unless params["max_hop"].nil?
>>>>>>> 4a8e834f9c90b7d954d5cd0aa7a54f1c5ed6c217

			results = []
			apgps.each do |apgp|

				results += GraphFinder::sparqlator(apgp, template["query"])

				data = {"apgp" => apgp, "frame" => frame}
				results += @graphfinder_ws.post data.to_json do |response, request, result|
					case response.code
					when 200
						res = JSON.parse response
						res.map{|r| {query:r, score:0.5}}
					else
						raise "Something wrong"
					end
				end
			end

			content_type :json
			results.to_json
		rescue => e
			content_type :json
<<<<<<< HEAD
=======
			result.map{|r| {query:r, score:0.5}}.to_json
		rescue => e
			content_type :json
>>>>>>> 4a8e834f9c90b7d954d5cd0aa7a54f1c5ed6c217
			{message: e.message}.to_json
		end
	end

end
