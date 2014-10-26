# Coursory
Coursory allows you to search and filter through Stanford courses. It fetches
courses from the ExploreCourses API, cleans/munges the data into MongoDB, and
indexes courses using Elasticsearch, providing a fast search API akin to Google
Instant.

This README will explain how to get coursory running on your local machine.


## Installing Dependencies
Install [MongoDB](http://docs.mongodb.org/manual/installation/) and
[Elasticsearch](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/_installation.html)
based on their respective installation instructions. Ensure they're both
running and ready to process requests.

You'll need ruby version 2.0.0. You can get this via [rvm](http://rvm.io/) or
[rbenv](https://github.com/sstephenson/rbenv).

Install bundler:

```bash
$ gem install bundler
```

Change into the coursory directory and install the project dependencies:

```bash
$ bundle install
```


## Configuring MongoDB
You'll need to tell coursory how to connect to MongoDB. Create a .env file in
the coursory directory and include the following:

```yaml
MONGODB_URI: mongodb://127.0.0.1/coursory
```

You can change the MongoDB URI if need be. See [the connection string URI
format](http://docs.mongodb.org/manual/reference/connection-string/) for
details.


## Seeding Courses
You'll need to seed your database with courses to get the search working. To
do so, change into the coursory directory and download an XML file containing
all courses from ExploreCourses:

```bash
$ curl
"explorecourses.stanford.edu/search?view=xml&filter-coursestatus-Active=on&page=0&catalog=&academicYear=&q=%"
> courses.xml
```

Then, parse and sync the course data into MongoDB:

```bash
$ ./bin/sync_courses.rb
```

Munge/Clean the data to make it easily searchable:

```bash
$ ./bin/clean_courses.rb
```

Finally, index it using Elasticsearch:

```bash
$ ./bin/index_courses.rb
```

Confirm everything worked by running the REPL:

```bash
$ ./bin/repl

[4] pry(main)> Course.where(:code => '144', :subject => 'CS').first
```

If you see CS 144, everything should have worked.


## Running Coursory
Now that you've installed dependencies and set up your database, you can run
coursory:

```bash
$ rackup
```

Make a request to the search API to see if things are working:

```bash
$ curl "localhost:9292/search?query=cs+155"
```

If you see CS 155 as the first search result, you should be good to go!
Consider using the [`jq`](http://stedolan.github.io/jq/) command-line tool to
format the JSON readably:

```bash
$ curl "localhost:9292/search?query=cs+155" | jq '.'
```

Now, visit [http://localhost:9292](http://localhost:9292) in your browser and
you should see the working coursory app. Happy developing!
