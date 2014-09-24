require 'mongo_mapper'
MongoMapper.setup({'production' => {'uri' => ENV['MONGODB_URI']}}, 'production')

require 'models/section'
require 'models/course'
