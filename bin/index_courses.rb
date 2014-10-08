#!/usr/bin/env ruby
require File.expand_path('../../app', __FILE__)
require 'elasticsearch'

INDEXED_ATTRS = ['year', 'subject', 'code', 'subject_code', 'title',
                 'description', 'gers', 'instructors', 'terms', 'units']

def main
  client = Elasticsearch::Client.new(:log => true)

  # configure index for searching 
  indices = client.indices
  indices.delete(:index => 'courses') if indices.exists(:index => 'courses')

  indices.create(:index => 'courses', :body => {
    :settings => {
      :number_of_shards => 1,

      :analysis => {
        :filter => {
          :autocomplete_filter => { 
            :type => 'edge_ngram',
            :min_gram => 1,
            :max_gram => 20,
          }
        },

        :analyzer => {
          :autocomplete => {
            :type => 'custom',
            :tokenizer => 'standard',
            :filter => [
              'lowercase',
              'autocomplete_filter',
            ]
          }
        }
      },
    },

    :mappings => {
      :course => {
        :properties => {
          :year => {
            :type => 'string',
            :index_analyzer => 'autocomplete',
            :search_analyzer => 'standard',
          },

          :subject => {
            :type => 'string',
            :index => 'not_analyzed',
          },

          :code => {
            :type => 'string',
            :index => 'not_analyzed',
          },

          :subject_code => {
            :type => 'string',
            :index_analyzer => 'autocomplete',
            :search_analyzer => 'standard',
          },

          :title => {
            :type => 'string',
            :index_analyzer => 'autocomplete',
            :search_analyzer => 'standard',
          },

          :description => {
            :type => 'string',
            :index_analyzer => 'autocomplete',
            :search_analyzer => 'standard',
          },

          :gers => {
            :type => 'string',
            :index => 'not_analyzed',
          },

          :instructors => {
            :type => 'string',
            :index_analyzer => 'autocomplete',
            :search_analyzer => 'standard',
          },

          :terms => {
            :type => 'string',
            :index => 'not_analyzed',
          },

          :units => {:type => 'integer'},
        }
      }
    }
  })

  Course.each do |course|
    # don't index courses that are not given
    next if course.terms == [] || course.instructors == []
    document = course.to_mongo

    # subject and code are combined into one field since they're often searched
    # for together. note that we allow for an optional space between them.
    subject = document['subject']
    code = document['code']
    document['subject_code'] = "#{subject} #{code}"

    document.delete_if {|key, value| !INDEXED_ATTRS.include?(key)}
    puts "Indexing #{document['subject_code']}: #{document['title']}"

    data = client.index(:index => ECI::Search::ES_INDEX_NAME,
                        :type => ECI::Search::ES_TYPE_NAME,
                        :body => document)
    course.es_uid = data['_id']
    course.save
  end
end

main
