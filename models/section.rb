module ECI
  module Models
    class Section
      include MongoMapper::EmbeddedDocument

      key :class_id, String
      key :term, String
      key :units, Integer

      key :section_num, String
      key :component, String

      key :schedule, String
      key :instructors, String
      key :notes, String
    end
  end
end
