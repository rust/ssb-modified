# request.rb - HTTP request
#
# Author:: MIZOGUCHI Coji <mizoguchi.coji at gmail.com>
# License:: Distributes under the same terms as Ruby
#
# $Id: request.rb 16139 2008-07-23 12:59:54Z drry $
#
require 'cgi'
require 'net/http'
require 'net/https'
require 'nkf'
require 'ssb/misc'
require 'uri'
Net::HTTP::version_1_2

module SSB
  #
  # Request for SSB
  #
  class Request
    attr_reader :uri
    attr_reader :method         # request methods that is 'GET' or 'POST'.
    attr_reader :post_params    # POST parameters
    attr_reader :term           # Terminal configuration

    def initialize(method, in_query, in_cookie)
      @method = method
      @term = SSB::Misc.load_terminal_info(in_cookie)
      @http_proxy = ENV['HTTP_PROXY'] || ENV['http_proxy']
      parse_query(in_query)
    end

    def self.build_request(cgi)
      Request.new(cgi.request_method,
                  cgi.query,
                  cgi.cookies)
    end

    def http_class(http_proxy = nil)
      return Net::HTTP unless http_proxy
      uri = URI.parse(http_proxy)
      user, pass = uri.userinfo.split(/:/) if uri.userinfo
      address = uri.host
      port = uri.port
      Net::HTTP.Proxy(address, port, user, pass)
    end

    def uri
      @term.get_transformed_uri(@uri)
    end

    def request_header
      @term.get_request_header(true)
    end

    def execute
      return nil if @uri.to_s == 'about:blank'
      begin
        http = http_class(@http_proxy).new(@uri.host, @uri.port)
        if @uri.scheme == 'https'
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        http.start do
          case method
          when 'GET'
            http.get(@uri.request_uri, request_header.update({'Host' => "#{@uri.host}:#{@uri.port}",
                                                              'x-ssb' => 'server-side-browser'}))
          when 'POST'
            http.post(@uri.request_uri,
                      @post_params,
                      request_header.update({'Host' => "#{@uri.host}:#{@uri.port}",
                                             'Content-Type' => 'application/x-www-form-urlencoded',
                                             'x-ssb' => 'server-side-browser'
                                             }))
          else
            nil
          end
        end
      rescue =>e
        e.to_s + '<hr />' + e.backtrace.to_s
      end
    end

    private
    def parse_query(in_query)
      uri_base   = nil
      uri_params = []

      in_query.keys.each do |key|
        if key == 'ssb_q'       # request URI
          uri_base = in_query[key].dup.untaint unless in_query[key].nil?
        else
          uri_params << in_query[key].list.map do |value|
            "#{NKF::nkf('-s -x', key.dup.untaint)}=#{WEBrick::HTTPUtils.escape_form(NKF::nkf('-s -x', value.dup.untaint))}"
          end
        end
      end

      uri_base = SSB::config['default']['homepage'] if uri_base.nil? || uri_base == ''
      uri_base = 'http://' + uri_base unless uri_base =~ %r[https?://|about:blank]

      begin
        if uri_params.size == 0
          @uri = URI.parse(uri_base)
        else
          query = uri_params.join('&')
          case method
          when 'GET'
            @uri = URI.parse(uri_base + '?' + query)
          when 'POST'
            @uri = URI.parse(uri_base)
            @post_params = query
          end
        end
      rescue =>e
        @uri = nil
      end
    end
  end
end

