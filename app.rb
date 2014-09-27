require 'rubygems'
require 'bundler'

Bundler.require
$: << File.expand_path('../', __FILE__)

require 'dotenv'
Dotenv.load

require 'nyny'
require 'models'
require 'search'

module ECI
  class App < NYNY::App
    ES_INDEX_NAME = 'courses'
    ES_TYPE_NAME = 'course'

    use Rack::Static, :urls => ['/css', '/js', '/images'], :root => 'public'

    # home page with search box
    get '/' do
      render('index.erb', :title => 'Explore Courses Instant')
    end

    # returns courses that match the given query in JSON
    get '/search' do
      query = params[:query]

      # ensure valid query
      if !query or query == ''
        status 422
        halt
      end

      courses = ECI::Search.match(query)
      headers['Content-Type'] = 'application/json'
      courses.to_json
    end
  end
end

include ECI::Models
