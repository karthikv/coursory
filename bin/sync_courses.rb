#!/usr/bin/env ruby
require File.expand_path('../../app', __FILE__)
require 'nokogiri'

# Course model key => XML tag
COURSE_KEY_TO_TAG = {
  :year => 'year',
  :subject => 'subject',
  :code => 'code',
  :title => 'title',
  :description => 'description',
  :ger_str => 'gers'
}

# Section model key => XML tag
SECTION_KEY_TO_TAG = {
  :class_id => 'classId',
  :term => 'term',
  :units => 'units',
  :section_num => 'sectionNumber',
  :component => 'component',
  :schedule => 'schedule',
  :instructors => 'instructors',
  :notes => 'notes'
}

def main
  courses_file_path = File.expand_path('../../courses.xml', __FILE__)
  courses_file = File.open(courses_file_path, 'r')

  doc = Nokogiri::XML(courses_file)
  Course.destroy_all

  doc.css('course').each do |course_doc|
    # collect sections into one list
    sections = course_doc.css('section').map do |section_doc|
      section = {}
      SECTION_KEY_TO_TAG.each do |key, tag|
        section[key] = section_doc.css(tag).first.text
      end

      section
    end

    # create course
    course = {}
    COURSE_KEY_TO_TAG.each do |key, tag|
      course[key] = course_doc.css(tag).first.text
    end

    puts "Creating course #{course[:subject]}#{course[:code]}: #{course[:title]}"
    course[:sections] = sections
    Course.create(course)
  end

  courses_file.close
end

main
