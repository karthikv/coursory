module ECI
  module Models
    class Course
      include MongoMapper::Document
      many :sections

      key :year, String
      key :subject, String
      key :code, String

      key :title, String
      key :description, String
      key :gers, String

      # elastic search ID
      key :es_uid, String

      timestamps!

      def to_public_hash
        return {
          :year => year,
          :subject => subject,
          :code => code,
          :title => title,
          :description => description,
          :gers => gers
        }
      end
    end
  end
end
