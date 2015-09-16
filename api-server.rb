require 'sinatra'

configure {
  set :server, :puma
}
 
class ApiServer < Sinatra::Base
  API_PROXY_URL = "http://labs.data.gov/csv-to-api/index.php"
  DATA_FILES = {
    greyhounds: {
      url: "http://www.betfairpromo.com/betfairsp/prices/dwbfgreyhoundplace15092015.csv",
      fields: []
    }
  }

  def api_resp_header format
    case format.downcase
      when 'json' then content_type 'application/json'
      when 'xml' then content_type 'application/xml'
      when 'html' then content_type 'text/html'
      else error 400, "Unsuitable response format: \"#{format}\". Supported response formats are json, xml and html."
    end
  end

  get '/api/v0/:api_name.?:format?' do

    # Check that we have an API for that dataset
    api_name = params[:api_name].downcase.to_sym
    error(404, "No API for the dataset \"#{api_name}\"") unless DATA_FILES.has_key? api_name
    options = {query: {source: DATA_FILES[api_name][:url], source_format: 'csv'}}

    # Global API options
    %w{callback sort sort_dir}.map(&:to_sym).each do |api_option|
      options[:query][api_option] = params[api_option] unless params[api_option].nil?
    end
    
    # Handle return format
    params[:format] = 'json' if params[:format].nil?
    options[:query][:format] = params[:format]
    api_resp_header params[:format]
    
    # Call the CSV-to-API endpoint
    HTTParty.get(API_PROXY_URL, options).body 
  end

  run! if app_file == $0
end