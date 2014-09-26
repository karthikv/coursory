#!/usr/bin/env ruby
require File.expand_path('../../app', __FILE__)

TERM_MAP = {
  '2014-2015 Autumn' => 'Autumn'
}

def main
  Course.each do |course|
    # get rid of 'GER:' prefix
    course.gers = course.gers.gsub(/^\s*GER:\s*/, '')

    # compute and store all terms
    terms = course.sections.map do |section|
      section.term.gsub('2014-2015 ', '')
    end
    course.terms = terms.uniq

    # compute and store all instructors
    instructors = []
    course.sections.each do |section|
      if section.instructors && section.instructors != ''
        section_instructors = section.instructors.split(';').map(&:strip)
        instructors.concat(section_instructors)
      end
    end

    course.instructors = instructors

    puts "Cleaning #{course.subject} #{course.code}; terms=#{course.terms}, " +
         "instructors=#{course.instructors}"
    course.save
  end
end

main
