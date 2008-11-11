# ssb を Rack に対応させる(実験的実装)
require 'rubygems'
require 'rack'
require 'webrick'

class Rack::Request

  alias_method :origin_cookies, :cookies

  def query
    Rack::Utils.parse_query(query_string)
  end

  # rack.request.cookie_hash の形式に自信なし
  def cookies
    rack_cookies = origin_cookies.dup
    cgi_cookie = {}
    ['path', 'domain', 'expires', 'secure'].each do |attr_name|
      cgi_cookie[attr_name] = rack_cookies.delete(attr_name) if rack_cookies.has_key?(attr_name)
    end
    cookies = []
    rack_cookies.each do |name, value|
      ck = ::WEBrick::Cookie.new(name, value)
      cgi_cookie.each do |attr_name, attr_value|
        ck.send("attr_name=".to_sym, attr_value) if ck.respond_to?("attr_name=".to_sym)
      end
      cookies << ck
    end
    cookies
  end

end

class FakeResponse

  attr_accessor :header, :body

  def initialize
    @header = {
      'Content-Type' => 'text/html; charset=UTF-8'
    }
    @body = ''
  end

end

class SSB::Application

  def call(env)
    @time_stamp.stamp(:request_start)
    rack_request = Rack::Request.new(env)
    rack_response = FakeResponse.new

    # リクエストの生成
    server_name = env['HTTP_HOST'] || env['SERVE_NAME']
    path = File.basename(env['SCRIPT_NAME'])
    @ssb_uri = 'http://' + server_name + path + '/'
    @request = SSB::Request.build_request(rack_request)

    # ログ
    log(@request.method, @request.uri, @request.term.get_useragent(true), @request.term[:uid])

    # リクエスト
    source = ''
    response = @request.execute

    # リクエスト終了
    @time_stamp.stamp(:request_finish)

    page,source = process_response(rack_response, response)

    body = rack_response.body
    if rack_response.body == ''
      body = output_template(@request.uri,
                             response,
                             @request.term,
                             page,
                             source,
                             rack_response)
    end

    [200, rack_response.header, [body]]
  end

end
