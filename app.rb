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
    use Rack::Static, :urls => ['/css', '/js', '/images'], :root => 'public'

    get '/' do
      render('index.erb', :title => 'Explore Courses Instant')
    end

    get '/search' do
      query = params[:query]

      if !query or query == ''
        status 422
        halt
      end

      es = Elasticsearch::Client.new
      results = es.search(
        :index => 'courses',
        :type => 'course',
        :body => {
          :query => {
            :multi_match => {
              :query => query,
              :fields => ['year', 'subject_code^2', 'title^1.5', 'description', 'gers'],
              :minimum_should_match => '70%'
            }
          }
        }
      )

      hits = results['hits']['hits']
      hits.each do |hit|
        course = Course.where(:es_uid => hit['_id']).first
        if !course
          puts "Hit #{hit} doesn't have course"
        end
      end
      courses = hits.map {|hit| Course.where(:es_uid => hit['_id']).first}
      courses = courses.map {|course| course.to_public_hash}

      headers['Content-Type'] = 'application/json'
      courses.to_json
    end
  end
end

include ECI::Models
