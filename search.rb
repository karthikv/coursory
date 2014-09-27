require 'elasticsearch'

module ECI
  class Search
    ES_INDEX_NAME = 'courses'
    ES_TYPE_NAME = 'course'

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

    # Returns an array of courses that match the given query.
    def self.match(query)
      # search via Elasticsearch
      es = Elasticsearch::Client.new
      results = es.search(
        :index => ES_INDEX_NAME,
        :type => ES_TYPE_NAME,
        :body => {
          :query => {
            :multi_match => {
              :query => self.split_course_numbers(query),

              # boost subject and title so that precise searches give the right results
              :fields => ['year', 'subject_code^2', 'title^1.5', 'description', 'gers'],
              :minimum_should_match => '70%'
            }
          }
        }
      )

      hits = results['hits']['hits']
      courses = hits.map {|hit| Course.where(:es_uid => hit['_id']).first}
      courses = courses.map {|course| course.to_public_hash}
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
