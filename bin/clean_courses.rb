#!/usr/bin/env ruby
require File.expand_path('../../app', __FILE__)
require 'sanitize'

def main
  Course.each do |course|
    # get rid of 'GER:' prefix
    course.gers = course.gers.gsub(/^\s*GER:\s*/, '')

    # clean section
    course.sections.each do |section|
      section.term = section.term.gsub('2014-2015 ', '')
      section.schedule = Sanitize.clean(section.schedule).gsub(/\s*with.*?$/, '')
    end

    # compute and store all sections
    terms = course.sections.map {|section| section.term}
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

    puts "Cleaning #{course.subject} #{course.code}"
    course.save
  end
end

main
