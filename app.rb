require 'rubygems'
require 'bundler'

Bundler.require
$: << File.expand_path('../', __FILE__)

require 'dotenv'
Dotenv.load

require 'nyny'
require 'models'

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

      # search via Elasticsearch
      es = Elasticsearch::Client.new
      results = es.search(
        :index => ES_INDEX_NAME,
        :type => ES_TYPE_NAME,
        :body => {
          :query => {
            :multi_match => {
              :query => query,

              # boost subject and title so that precise searches give the right results
              :fields => ['year', 'subject_code^2', 'title^1.5', 'description', 'gers'],
              :minimum_should_match => '70%'
            }
          }
        }
      )

      hits = results['hits']['hits']
      courses = hits.map {|hit| Course.where(:es_uid => hit['_id']).first}
      courses = courses.map {|course| course.to_public_hash}

      headers['Content-Type'] = 'application/json'
      courses.to_json
    end
  end
end

include ECI::Models
