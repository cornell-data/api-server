require 'sinatra'
require 'yaml'

configure {
  set :server, :puma
}
 
class ApiServer < Sinatra::Base

  ########################################
  # CONFIG                               #
  ########################################

  API_PROXY_URL = "http://localhost:8000/index.php"
  DATA_FILES = YAML.load_file 'config/datasets.yaml'

  ########################################
  # HELPER METHODS                       #
  ########################################

  def api_resp_header format
    case format.downcase
      when 'json' then content_type 'application/json'
      when 'xml' then content_type 'application/xml'
      when 'html' then content_type 'text/html'
      else error 400, "Unsuitable response format: \"#{format}\". Supported response formats are json, xml and html."
    end
  end

  def api_data_url api_name, method_name
    "https://raw.githubusercontent.com/cornell-data/#{api_name}/master/#{method_name}/#{method_name}.csv"
  end

  ########################################
  # ENDPOINTS                            #
  ########################################

  get '/api/v0/?' do
    'API V0'
  end

  get '/api/v0/:api_name/?:method_name?.?:format?' do

    # Check that we have an API for that dataset and method
    api_name = params[:api_name]
    error(404, "No API for the dataset \"#{api_name}\"") unless DATA_FILES.has_key? api_name
    method_name = if params[:method_name].nil? then 'data' else params[:method_name] end
    error(404, "No API method \"#{method_name}\" for the dataset \"#{api_name}\"") unless DATA_FILES[api_name].has_key? method_name

    options = {query: {source: api_data_url(api_name, method_name), source_format: 'csv', header_row: 'y'}}

    # Filterable options + global API options
    allowed_params = DATA_FILES[api_name][method_name]['fields'] + %w{callback sort sort_dir}
    allowed_params.map(&:to_sym).each do |api_option|
      options[:query][api_option] = params[api_option] unless params[api_option].nil?
    end
    
    # Handle return format
    params[:format] = 'json' if params[:format].nil?
    options[:query][:format] = params[:format]
    api_resp_header params[:format]
    
    # Call the CSV-to-API endpoint
    HTTParty.get(API_PROXY_URL, options).body 
  end

  ########################################
  # BOOTSTRAP                            #
  ########################################

  run! if app_file == $0
end