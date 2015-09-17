require 'sinatra'

configure {
  set :server, :puma
}
 
class ApiServer < Sinatra::Base
  API_PROXY_URL = "http://labs.data.gov/csv-to-api/index.php"
  DATA_FILES = {
    'map-data' => {
      'bikeracks' => {
        fields: ['Latitude', 'Longitude']
      },
      'bluelights' => {
        fields: ['Name', 'Latitude', 'Longitude']
      },
      'buildings' => {
        fields: ['Name', 'Category', 'ImageURL', 'Address', 'Latitude', 'Longitude', 'Notes', 'AKA']
      },
      'campustocampus' => {
        fields: ['Name', 'Latitude', 'Longitude']
      },
      'diaperchangingstations' => {
        fields: ['Latitude', 'Longitude']
      },
      'infobooths' => {
        fields: ['Name', 'Latitude', 'Longitude']
      },
      'lactationrooms' => {
        fields: ['Name', 'Latitude', 'Longitude']
      },
      'parkmobile' => {
        fields: ['ID', 'Name', 'Latitude', 'Longitude', 'Address', 'Notes']
      },
      'virtualtour' => {
        fields: ['ID', 'Name', 'Description', 'PanDegrees', 'TiltDegrees', 'Latitude', 'Longitude', 'View']
      }
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

  def api_data_url api_name, method_name
    "https://raw.githubusercontent.com/cornell-data/#{api_name}/master/#{method_name}/#{method_name}.csv"
  end

  get '/api/v0' do
    'API V0'
  end

  get '/api/v0/:api_name/:method_name?.?:format?' do

    # Check that we have an API for that dataset and method
    api_name = params[:api_name]
    error(404, "No API for the dataset \"#{api_name}\"") unless DATA_FILES.has_key? api_name
    method_name = if params[:method_name].nil? then 'data' else params[:method_name] end
    error(404, "No API method \"#{method_name}\" for the dataset \"#{api_name}\"") unless DATA_FILES[api_name].has_key? method_name


    options = {query: {source: api_data_url(api_name, method_name), source_format: 'csv', header_row: 'y'}}

    # Global API options
    %w{callback sort sort_dir}.map(&:to_sym).each do |api_option|
      options[:query][api_option] = params[api_option] unless params[api_option].nil?
    end

    # Filter options
    DATA_FILES[api_name][method_name][:fields].map(&:to_sym).each do |filter_option|
      options[:query][filter_option] = params[filter_option] unless params[filter_option].nil?
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