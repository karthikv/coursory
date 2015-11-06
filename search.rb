require 'elasticsearch'
require 'json'

module ECI
  class Search
    ES_INDEX_NAME = 'courses'
    ES_TYPE_NAME = 'course'

    TERMS = ['Autumn', 'Winter', 'Spring', 'Summer']
    UNITS = [1, 2, 3, 4, 5, 6]

    GERS =  ['DB-EngrAppSci', 'DB-Hum', 'DB-Math', 'DB-NatSci', 'DB-SocSci',
      'EC-AmerCul', 'EC-EthicReas', 'EC-Gender', 'EC-GlobalCom', 'IHUM-1',
      'IHUM-2', 'IHUM-3', 'Language', 'THINK', 'WAY-A-II', 'WAY-AQR', 'WAY-CE',
      'WAY-ED', 'WAY-ER', 'WAY-FR', 'WAY-SI', 'WAY-SMA', 'Writing 1', 'Writing 2',
      'Writing SLE']

    SUBJECTS = ['AA', 'AMELANG', 'ACCT', 'AFRICAAM', 'AFRICAST', 'AMSTUD',
      'CSP', 'ANTHRO', 'ANES', 'CEE', 'APPPHYS', 'ARABLANG', 'ARCHLGY',
      'ARTHIST', 'ARTSINST', 'ARTSTUDI', 'ASNAMST', 'ATHLETIC', 'BIO', 'BIOC',
      'BIOE', 'CHINLIT', 'SIS', 'PHIL', 'TAPS', 'ASNLANG', 'BIOHOPK', 'BIOS',
      'CATLANG', 'CBIO', 'COMM', 'CSB', 'CSRE', 'DBIO', 'EARTHSYS', 'EASTASN',
      'ECON', 'FEMGEN', 'GENE', 'GEOPHYS', 'GERLANG', 'GES', 'GSBGEN',
      'HISTORY', 'HPS', 'HRP', 'HUMBIO', 'ITALLANG', 'JAPANGEN', 'JAPANLNG',
      'JEWISHST', 'KORGEN', 'LAW', 'BIOMEDIN', 'BIOPHYS', 'CHEM', 'CHEMENG',
      'CHILATST', 'CHINGEN', 'CHINLANG', 'CLASSART', 'CLASSGEN', 'CLASSICS',
      'CLASSLAT', 'CME', 'COMPLIT', 'COMPMED', 'CS', 'EDUC', 'SOC', 'DANCE',
      'DLCL', 'CTL', 'CTS', 'DDRL', 'DERM', 'EARTHSCI', 'EE', 'EEES', 'EESS',
      'FOODRES', 'PWR', 'SPECLANG', 'ENERGY', 'MATH', 'FINANCE', 'EFSLANG',
      'ENGLISH', 'ENVRES', 'ENVRINST', 'ETHICSOC', 'FAMMED', 'FRES', 'ME',
      'MED', 'MGTECON', 'MI', 'MKTG', 'OSPSANTG', 'PATH', 'PE', 'ENGR', 'ESF',
      'FEMST', 'FENG', 'FILMPROD', 'FILMSTUD', 'FRENCH', 'FRENLANG', 'GERMAN',
      'GLOBAL', 'HRMGT', 'HUMSCI', 'ICA', 'IIS', 'ILAC', 'IMMUNOL', 'INDE',
      'INTNLREL', 'IPS', 'ITALIAN', 'ITALIC', 'JAPANLIT', 'KORLANG', 'KORLIT',
      'LATINAM', 'LAWGEN', 'LEAD', 'LINGUIST', 'MATSCI', 'OSPBARCL', 'PSYCH',
      'IBERLANG', 'IE', 'LIBRARY', 'MLA', 'SIW', 'SLAVLANG', 'GERLIT',
      'GRXFER', 'HUMNTIES', 'MCP', 'MCS', 'MS&E', 'MTL', 'MUSIC', 'NATIVEAM',
      'NBIO', 'NENS', 'NEPR', 'NSUR', 'OB', 'OBGYN', 'OIT', 'OPHT', 'ORALCOMM',
      'ORTHO', 'OSPAUSTL', 'OSPBEIJ', 'OSPBER', 'OSPCPTWN', 'OSPFLOR',
      'OSPGEN', 'OSPISTAN', 'OSPKYOCT', 'OSPKYOTO', 'OSPMADRD', 'OSPOXFRD',
      'OSPPARIS', 'OTOHNS', 'OUTDOOR', 'PEDS', 'PHOTON', 'PHYSICS', 'POLECON',
      'POLISCI', 'PORTLANG', 'PSYC', 'MEDIS', 'RELIGST', 'PHRM', 'PUBLPOL',
      'ROTCARMY', 'ROTCNAVY', 'SPANLANG', 'STATS', 'STEMREM', 'SURG', 'RAD',
      'RADO', 'REES', 'ROTCAF', 'SBIO', 'SCCM', 'SIMILE', 'SLAVIC', 'SLE',
      'SOMGEN', 'SPANLIT', 'STRAMGT', 'STS', 'SYMBSYS', 'SYMSYS', 'THINK',
      'TIBETLNG', 'UAR', 'URBANST', 'UROL', 'WELLNESS', 'UAC', 'UGXFER', 'WCT',
      'SPEC']

    FILTER_KEYS = [:terms, :units, :gers, :subjects]
    FILTER_VALUES = {:terms => TERMS, :units => UNITS, :gers => GERS, :subjects => SUBJECTS}

    RESULTS_PER_PAGE = 10

    # Extracts filters from the user-inputted search parameters. Returns a hash
    # of filters to be passed to match() below.
    def self.extract_filters(params)
      filters = {}

      FILTER_KEYS.each do |key|
        next if !params[key]

        begin
          terms = JSON.parse(params[key])
        rescue JSON::ParserError
          # ignore filter
        else
          terms = terms.select {|term| FILTER_VALUES[key].include?(term)}
          filters[key] = terms if terms.length > 0
        end
      end

      # subjects -> subject for searching
      if filters[:subjects]
        filters[:subject] = filters[:subjects]
        filters.delete(:subjects)
      end

      filters
    end

    # Returns an array of courses that match the given query and filters. page
    # specifies which page of results to return (0-indexed)
    def self.match(query, filters, page)
      if !query || query.empty?
        # we're just filtering, so match all
        multi_match_query = {:match_all => {}}
      else
        multi_match_query = {
          :multi_match => {
            :query => self.split_course_numbers(query),

            # boost subject and title so that precise searches give the right results
            :fields => ['year', 'subject_code^2', 'title^1.5', 'description', 'gers'],
            :minimum_should_match => '70%',
          }
        }
      end

      if filters.empty?
        body = {:query => multi_match_query}
      else
        body = {
          :query => {
            :filtered => {
              :query => multi_match_query,
              :filter => {
                :terms => filters,
              }
            }
          }
        }

        if multi_match_query.has_key?(:match_all)
          # no search query; sort filtered results alphabetically
          body[:sort] = {:subject => {:order => :asc}}
        end
      end

      # search via Elasticsearch
      es = Elasticsearch::Client.new(:host => ENV['ES_HOST'])
      results = es.search(:index => ES_INDEX_NAME, :type => ES_TYPE_NAME,
        :body => body, :from => page * RESULTS_PER_PAGE)
      hits = results['hits']['hits']

      courses = hits.map {|hit| Course.where(:es_uid => hit['_id']).first}
      courses = courses.select {|course| course != nil}
      courses.map {|course| course.to_public_hash}
    end

    # Finds course numbers in the form '{subject}{code}', like 'CS106A' and
    # 'EE101'. Splits these up into 'CS 106A' and 'EE 101', respectively. The
    # latter form gives better search results in Elasticsearch, which considers
    # 'CS' and '106A' two separate tokens.
    def self.split_course_numbers(query)
      course_numbers_regex = Regexp.new('(' + SUBJECTS.join('|') + ')(\d+\w*)',
                                        Regexp::IGNORECASE)
      query.gsub(course_numbers_regex, '\1 \2')
    end
  end
end
