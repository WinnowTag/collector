#!/usr/bin/env ruby
# Universal feed parser in Ruby
#
# Handles RSS 0.9x, RSS 1.0, RSS 2.0, CDF, Atom 0.3, and Atom 1.0 feeds
#
# Visit http://feedparser.org/ for the latest version in Python
# Visit http://feedparser.org/docs/ for the latest documentation
# Email Jeff Hodges at jeff@somethingsimilar.com with questions
#
# Required: Ruby 1.8

$KCODE = 'UTF8'
require 'stringio'
require 'uri'
require 'open-uri'
require 'cgi' # escaping html
require 'time'
require 'pp'
require 'base64'
require 'iconv'
require 'zlib'

require 'rubygems'


# If available, Nikolai's UTF-8 library will ease use of utf-8 documents.
# See http://git.bitwi.se/ruby-character-encodings.git/.
begin
  gem 'character-encodings', ">=0.2.0"
  require 'encoding/character/utf-8'
rescue LoadError
end

# TODO: require these in the files that need them, not in the toplevel
gem 'hpricot', "=0.6"
require 'hpricot'

gem 'htmltools', ">=1.10"
require 'html/sgml-parser'

gem 'htmlentities', ">=4.0.0"
require 'htmlentities'

gem 'addressable', ">= 1.0.4"
require 'addressable/uri'

gem 'rchardet', ">=1.0"
require 'rchardet'
$chardet = true

$debug = false
$compatible = true

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))
require 'rfeedparser/utilities'
require 'rfeedparser/better_sgmlparser'
require 'rfeedparser/better_attributelist'
require 'rfeedparser/feedparserdict'
require 'rfeedparser/parser_mixin'

require 'rfeedparser/loose_feed_parser'

begin
  require 'rfeedparser/expat_parser'
  StrictFeedParser = FeedParser::Expat::StrictFeedParser
  
rescue LoadError, NameError
  STDERR.puts "Could not load expat; trying libxml."
  
  begin
    require 'rfeedparser/libxml_parser'
    StrictFeedParser = FeedParser::LibXML::StrictFeedParser

  rescue LoadError, NameError
    StrictFeedParser = nil
    STDERR.puts "Could not load libxml either; will use loose parser."
  end
end

require 'rfeedparser/monkey_patches'

module FeedParser
  extend FeedParserUtilities
  
  VERSION = "0.9.951"

  AUTHOR = "Mark Pilgrim <http://diveintomark.org/>"
  PORTER = "Jeff Hodges <http://somethingsimilar.com>"
  CONTRIBUTERS = ["Jason Diamond <http://injektilo.org/>",
                  "John Beimler <http://john.beimler.org/>",
                  "Fazal Majid <http://www.majid.info/mylos/weblog/>",
                  "Aaron Swartz <http://aaronsw.com/>",
                  "Kevin Marks <http://epeus.blogspot.com/>",
                  "Jesse Newland <http://jnewland.com/>",
                  "Charlie Savage <http://cfis.savagexi.com/>",
                  "Phil Hagelberg <http://technomancy.us>"]

  # HTTP "User-Agent" header to send to servers when downloading feeds.
  # If you are embedding feedparser in a larger application, you should
  # change this to your application name and URL.
  USER_AGENT = "rFeedParser/#{VERSION} +http://rfeedparser.rubyforge.org/"

  # HTTP "Accept" header to send to servers when downloading feeds.  If you don't
  # want to send an Accept header, set this to nil.
  ACCEPT_HEADER = "application/atom+xml,application/rdf+xml,application/rss+xml,application/x-netcdf,application/xml;q=0.9,text/xml;q=0.2,*/*;q=0.1"


  # If you want feedparser to automatically run HTML markup through HTML Tidy, set
  # this to true.  Requires mxTidy <http://www.egenix.com/files/python/mxTidy.html>
  # or utidylib <http://utidylib.berlios.de/>.
  #TIDY_MARKUP = false #FIXME untranslated

  # List of Python interfaces for HTML Tidy, in order of preference.  Only useful
  # if TIDY_MARKUP = true
  #PREFERRED_TIDY_INTERFACES = ["uTidy", "mxTidy"] #FIXME untranslated


  # ---------- don't touch these ----------
  class ThingsNobodyCaresAboutButMe < StandardError
  end
  class CharacterEncodingOverride < ThingsNobodyCaresAboutButMe
  end
  class CharacterEncodingUnknown < ThingsNobodyCaresAboutButMe
  end
  class NonXMLContentType < ThingsNobodyCaresAboutButMe
  end
  class UndeclaredNamespace < StandardError
  end


  SUPPORTED_VERSIONS = {'' => 'unknown',
    'rss090' => 'RSS 0.90',
    'rss091n' => 'RSS 0.91 (Netscape)',
    'rss091u' => 'RSS 0.91 (Userland)',
    'rss092' => 'RSS 0.92',
    'rss093' => 'RSS 0.93',
    'rss094' => 'RSS 0.94',
    'rss20' => 'RSS 2.0',
    'rss10' => 'RSS 1.0',
    'rss' => 'RSS (unknown version)',
    'atom01' => 'Atom 0.1',
    'atom02' => 'Atom 0.2',
    'atom03' => 'Atom 0.3',
    'atom10' => 'Atom 1.0',
    'atom' => 'Atom (unknown version)',
    'cdf' => 'CDF',
    'hotrss' => 'Hot RSS'
  }

  # Accepted in options: :agent, :modified, :etag, and :referrer 
  def open_resource(url_file_stream_or_string, options)
    options[:handlers] ||= []

    if url_file_stream_or_string.respond_to?(:read)
      return url_file_stream_or_string

    elsif url_file_stream_or_string == '-'
      return $stdin
    end
      
    # open-uri freaks out if there's leading spaces.
    url_file_stream_or_string.strip!
    
    
    uri = Addressable::URI.parse(url_file_stream_or_string)
    if uri && ['http','https','ftp'].include?(uri.scheme)
      auth = nil

      if uri.host && uri.password
        auth = Base64::encode64("#{uri.user}:#{uri.password}").strip
        uri.password = nil
        url_file_stream_or_string = uri.to_s
      end

      req_headers = {} 
      req_headers["User-Agent"] = options[:agent] || USER_AGENT
      req_headers["If-None-Match"] = options[:etag] if options[:etag]
      
      if options[:modified]
        if options[:modified].is_a?(String)
          req_headers["If-Modified-Since"] = parse_date(options[:modified]).httpdate
        elsif options[:modified].is_a?(Time)
          req_headers["If-Modified-Since"] = options[:modified].httpdate
        elsif options[:modified].is_a?(Array)
          req_headers["If-Modified-Since"] = py2rtime(options[:modified]).httpdate
        end
      end
      
      req_headers["Referer"] = options[:referrer] if options[:referrer]
      req_headers["Accept-encoding"] = 'gzip, deflate' # FIXME make tests
      req_headers["Authorization"] = "Basic #{auth}" if auth
      req_headers['Accept'] = ACCEPT_HEADER if ACCEPT_HEADER
      req_headers['A-IM'] = 'feed' # RFC 3229 support 
      
      begin
        return open(url_file_stream_or_string, req_headers) 
      rescue OpenURI::HTTPError => e
        return e.io
      rescue
      end
    end

    # try to open with native open function (if url_file_stream_or_string is a filename)
    begin 
      return open(url_file_stream_or_string)
    rescue
    end
    # treat url_file_stream_or_string as string          
    return StringIO.new(url_file_stream_or_string.to_s)
  end
  module_function(:open_resource)
  
  # Parse a feed from a URL, file, stream or string
  def parse(url_file_stream_or_string, options = {})
      
    
    # Use the default compatibility if compatible is nil
    $compatible = options[:compatible].nil? ? $compatible : options[:compatible]

    strictklass = options[:strict] || StrictFeedParser
    looseklass = options[:loose] || LooseFeedParser
    options[:handlers] = options[:handlers] || []
    
    result = FeedParserDict.new
    result['feed'] = FeedParserDict.new
    result['entries'] = []
    
    result['bozo'] = false
        
    begin
      f = open_resource(url_file_stream_or_string, options)
      data = f.read
    rescue => e
      result['bozo'] = true
      result['bozo_exception'] = e
      data = ''
      f = nil
    end
    
    if f and !(data.nil? || data.empty?) and f.respond_to?(:meta)
      # if feed is gzip-compressed, decompress it
      if f.meta['content-encoding'] == 'gzip'
        begin
          gz =  Zlib::GzipReader.new(StringIO.new(data))
          data = gz.read
          gz.close
        rescue => e
          # Some feeds claim to be gzipped but they're not, so
          # we get garbage.  Ideally, we should re-request the
          # feed without the 'Accept-encoding: gzip' header,
          # but we don't.
          result['bozo'] = true
          result['bozo_exception'] = e
          data = ''
        end
      elsif f.meta['content-encoding'] == 'deflate'
        begin
          data = Zlib::Deflate.inflate(data)
        rescue => e
          result['bozo'] = true
          result['bozo_exception'] = e
          data = ''
        end
      end
    end
    
    if f.respond_to?(:meta)
      result['etag'] = f.meta['etag']
      result['modified_time'] = parse_date(f.meta['last-modified'])
      result['modified'] = extract_tuple(result['modified_time'])
      result['headers'] = f.meta
    end
    
    # FIXME open-uri does not return a non-nil base_uri in its HTTPErrors. 
    if f.respond_to?(:base_uri)
      result['href'] = f.base_uri.to_s # URI => String
      result['status'] = '200'
    end
    
    if f.respond_to?(:status)
      result['status'] = f.status[0] 
    end


    # there are four encodings to keep track of:
    # - http_encoding is the encoding declared in the Content-Type HTTP header
    # - xml_encoding is the encoding declared in the <?xml declaration
    # - sniffed_encoding is the encoding sniffed from the first 4 bytes of the XML data
    # - result['encoding'] is the actual encoding, as per RFC 3023 and a variety of other conflicting specifications
    http_headers = result['headers'] || {}
    result['encoding'], http_encoding, xml_encoding, sniffed_xml_encoding, acceptable_content_type =
    getCharacterEncoding(http_headers, data)


    if !(http_headers.nil? || http_headers.empty?) && !acceptable_content_type
      if http_headers['content-type']
        bozo_message = "#{http_headers['content-type']} is not an XML media type"
      else
        bozo_message = 'no Content-type specified'
      end

      result['bozo'] = true
      result['bozo_exception'] = NonXMLContentType.new(bozo_message) # I get to care about this, cuz Mark says I should.
    end

    result['version'], data = stripDoctype(data)
    
    baseuri = http_headers['content-location'] || result['href']
    baselang = http_headers['content-language']

    # if server sent 304, we're done
    if result['status'] == 304
      result['version'] = ''
      result['debug_message'] = "The feed has not changed since you last checked, " +
      "so the server sent no data. This is a feature, not a bug!"
      return result
    end

    # if there was a problem downloading, we're done
    if data.nil? or data.empty?
      return result
    end

    # determine character encoding
    use_strict_parser = false
    known_encoding = false
    tried_encodings = []
    proposed_encoding = nil
    # try: HTTP encoding, declared XML encoding, encoding sniffed from BOM
    [result['encoding'], xml_encoding, sniffed_xml_encoding].each do |proposed_encoding|
      next if proposed_encoding.nil? or proposed_encoding.empty?
      next if tried_encodings.include? proposed_encoding
      tried_encodings << proposed_encoding
      begin
        data = toUTF8(data, proposed_encoding)
        known_encoding = use_strict_parser = true
        break
      rescue
      end
    end

    # if no luck and we have auto-detection library, try that
    if not known_encoding and $chardet
      begin 
        proposed_encoding = CharDet.detect(data)['encoding']
        if proposed_encoding and not tried_encodings.include?proposed_encoding
          tried_encodings << proposed_encoding
          data = toUTF8(data, proposed_encoding)
          known_encoding = use_strict_parser = true
        end
      rescue
      end
    end

    # if still no luck and we haven't tried utf-8 yet, try that
    if not known_encoding and not tried_encodings.include?'utf-8'
      begin
        proposed_encoding = 'utf-8'
        tried_encodings << proposed_encoding
        data = toUTF8(data, proposed_encoding)
        known_encoding = use_strict_parser = true
      rescue
      end
    end

    # if still no luck and we haven't tried windows-1252 yet, try that
    if not known_encoding and not tried_encodings.include?'windows-1252'
      begin
        proposed_encoding = 'windows-1252'
        tried_encodings << proposed_encoding
        data = toUTF8(data, proposed_encoding)
        known_encoding = use_strict_parser = true
      rescue
      end
    end

    # NOTE this isn't in FeedParser.py 4.1
    # if still no luck and we haven't tried iso-8859-2 yet, try that.
    #if not known_encoding and not tried_encodings.include?'iso-8859-2'
    #  begin
    #    proposed_encoding = 'iso-8859-2'
    #    tried_encodings << proposed_encoding
    #    data = toUTF8(data, proposed_encoding)
    #    known_encoding = use_strict_parser = true
    #  rescue
    #  end
    #end


    # if still no luck, give up
    if not known_encoding
      result['bozo'] = true
      result['bozo_exception'] = CharacterEncodingUnknown.new("document encoding unknown, I tried #{result['encoding']}, #{xml_encoding}, utf-8 and windows-1252 but nothing worked")
      result['encoding'] = ''
    elsif proposed_encoding != result['encoding']
      result['bozo'] = true
      result['bozo_exception'] = CharacterEncodingOverride.new("documented declared as #{result['encoding']}, but parsed as #{proposed_encoding}")
      result['encoding'] = proposed_encoding
    end

    use_strict_parser = false unless StrictFeedParser

    if use_strict_parser
      begin
        parser = StrictFeedParser.new(baseuri, baselang)
        feedparser = parser.handler
        parser.parse(data)

      rescue => err
        $stderr << "xml parsing failed: #{err.message}\n#{err.backtrace.join("\n")}" if $debug
        result['bozo'] = true
        result['bozo_exception'] = feedparser.exc || e 
        use_strict_parser = false
      end
    end
    
    if not use_strict_parser
      $stderr << "Using LooseFeed\n\n" if $debug
      feedparser = looseklass.new(baseuri, baselang, (known_encoding and 'utf-8' or ''))
      feedparser.parse(data)
    end

    result['feed'] = feedparser.feeddata
    result['entries'] = feedparser.entries
    result['version'] = result['version'] || feedparser.version
    result['namespaces'] = feedparser.namespacesInUse
    return result
  end
  module_function(:parse)
end # End FeedParser module

def rfp(url_file_stream_or_string, options={})
  FeedParser.parse(url_file_stream_or_string, options)
end

class Serializer 
  def initialize(results)
    @results = results
  end
end

class TextSerializer < Serializer
  def write(stream=$stdout)
    writer(stream, @results, '')
  end

  def writer(stream, node, prefix)
    return if (node.nil? or node.empty?)
    if node.methods.include?'keys'
      node.keys.sort.each do |key|
        next if ['description','link'].include? key
        next if node.has_key? k+'_detail'
        next if node.has_key? k+'_parsed'
        writer(stream,node[k], prefix+k+'.')
      end
    elsif node.class == Array
      node.each_with_index do |thing, index|
        writer(stream, thing, prefix[0..-2] + '[' + index.to_s + '].')
      end
    else
      begin
        s = u(node.to_s)
        stream << prefix[0..-2]
        stream << '='
        stream << s
        stream << "\n"
      rescue
      end
    end
  end
end

class PprintSerializer < Serializer # FIXME use pp instead
  def write(stream = $stdout)
    stream << @results['href'].to_s + "\n\n"
    pp(@results)
    stream << "\n"
  end
end

if $0 == __FILE__
  require 'optparse'
  require 'ostruct'
  options = OpenStruct.new
  options.etag = options.modified = options.agent = options.referrer = nil
  options.content_language = options.content_location = options.ctype = nil
  options.format = 'pprint'
  options.compatible = $compatible 
  options.verbose = false

  opts = OptionParser.new do |opts|
    opts.banner 
    opts.separator ""
    opts.on("-A", "--user-agent [AGENT]",
    "User-Agent for HTTP URLs") {|agent|
      options.agent = agent
    }

    opts.on("-e", "--referrer [URL]", 
    "Referrer for HTTP URLs") {|referrer|
      options.referrer = referrer
    }

    opts.on("-t", "--etag [TAG]",
    "ETag/If-None-Match for HTTP URLs") {|etag|
      options.etag = etag
    }

    opts.on("-m", "--last-modified [DATE]",
    "Last-modified/If-Modified-Since for HTTP URLs (any supported date format)") {|modified|
      options.modified = modified
    }

    opts.on("-f", "--format [FORMAT]", [:text, :pprint],
    "output resutls in FORMAT (text, pprint)") {|format|
      options.format = format
    }

    opts.on("-v", "--[no-]verbose",
    "write debugging information to stderr") {|v|
      options.verbose = v
    }

    opts.on("-c", "--[no-]compatible",
    "strip element attributes like feedparser.py 4.1 (default)") {|comp|
      options.compatible = comp
    }
    opts.on("-l", "--content-location [LOCATION]",
    "default Content-Location HTTP header") {|loc|
      options.content_location = loc
    }
    opts.on("-a", "--content-language [LANG]",
    "default Content-Language HTTP header") {|lang|
      options.content_language = lang
    }
    opts.on("-t", "--content-type [TYPE]",
    "default Content-type HTTP header") {|ctype|
      options.ctype = ctype
    }
  end

  opts.parse!(ARGV)
  $debug = true if options.verbose 
  $compatible = options.compatible unless options.compatible.nil?

  if options.format == :text
    serializer = TextSerializer
  else
    serializer = PprintSerializer
  end
  args = *ARGV.dup
  unless args.nil? 
    args.each do |url| # opts.parse! removes everything but the urls from the command line
      results = FeedParser.parse(url, :etag => options.etag, 
      :modified => options.modified, 
      :agent => options.agent, 
      :referrer => options.referrer, 
      :content_location => options.content_location,
      :content_language => options.content_language,
      :content_type => options.ctype
      )
      serializer.new(results).write($stdout)
    end
  end
end
