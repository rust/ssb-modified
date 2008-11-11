require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require 'ssb/request'
require 'webrick/cookie'
require 'webrick/httputils'

$SAFE = 1

unit_tests do
  def request_params
    {
      'ssb_q'.taint  => MockServer.uri.dup.taint,
      'p1'.taint => WEBrick::HTTPUtils::FormData.new('foo'.taint),
      'p2'.taint => WEBrick::HTTPUtils::FormData.new('bar'.taint),
      'p3'.taint => WEBrick::HTTPUtils::FormData.new('bazz&hoge'.taint)
    }
  end

  def cookie
    ret = []
    {
      'homepage'.taint  => 'http://example.com/'.taint,
      'mailaddr'.taint  => 'coji.mizo@example.com'.taint,
      'useragent'.taint => 'DoCoMo/2.0 N902i(c100;TB;hid;icc)'.taint,
      'uid'.taint       => 'NULLGWDOCOMO'.taint,
      'hid'.taint       => 'hidhidhid'.taint,
      'icc'.taint       => 'icciccicc'.taint,
      'exheader'.taint  => 'X-Hoge: hoge'.taint,
    }.each {|key, val|
      ret.push WEBrick::Cookie.new(key, val)
    }
    ret
  end

  def setup
    @http_proxy, @HTTP_PROXY = ENV['HTTP_PROXY'], ENV['http_proxy']
    ENV['HTTP_PROXY'], ENV['http_proxy'] = nil, nil
    @request = SSB::Request.new('GET', request_params, cookie)
  end

  def teardown
    ENV['HTTP_PROXY'], ENV['http_proxy'] = @http_proxy, @HTTP_PROXY
  end

  test 'instance' do
    assert_not_nil(@request)
  end

  test 'request_method' do
    assert_instance_of(String, @request.method)
    assert_equal(@request.method, 'GET')
    assert(!@request.method.tainted?)
  end

  test 'request_uri_should_uri' do
    assert_instance_of(URI::HTTP, @request.uri)
  end

  test 'request_uri_should_start_with_http' do
    assert(@request.uri.to_s =~ /^http:\/\//)
  end

  test 'request_uri_should_encoded' do
    assert_equal(@request.uri.to_s, "#{MockServer.uri}?p1=foo&p2=bar&p3=bazz%26hoge")
  end

  test 'request_uri_should_not_tainted' do
    assert(!@request.uri.to_s.tainted?)
  end

  test 'request_post_params' do
    assert_equal(@request.post_params, nil)
  end

  test 'request_term_should_not_nil' do
    assert_not_nil(@request.term)
  end

  test 'request_term_keys_should_not_tainted_and_valid_value' do
    assert_not_nil(@request.term)
    test_keys = ['homepage', 'mailaddr', 'useragent', 'uid', 'hid', 'icc']
    test_keys.each do |key|
      assert_equal(@request.term[key.to_sym].to_s, cookie.find {|x| x.name == key }.value )
      assert(!@request.term[key].tainted?)
    end
  end

  test 'request_header_should_exist' do
    assert_not_nil(@request.request_header)
  end

  test 'request_header_should_have_useragent' do
    assert(@request.request_header.has_key?('User-Agent'))
  end

  test 'request_header_shuold_vaild_useragent_with_hid' do
    assert_equal(@request.request_header['User-Agent'], 'DoCoMo/2.0 N902i(c100;TB;hidhidhid;icciccicc)')
  end

  test 'request_header_should_have_exheader' do
    assert(@request.request_header.has_key?('X-Hoge'))
  end

  test 'test_request_header_shuold_valid_exheader' do
    assert_equal(@request.request_header['X-Hoge'], 'hoge')
  end

  test 'about:blank uri' do
    request = SSB::Request.new('GET', {'ssb_q'.taint => 'about:blank'.taint}, cookie)
    assert_not_nil(request.uri)
    assert_instance_of(URI::Generic, request.uri)
    assert_equal(request.uri.scheme, 'about')
    assert_equal(request.uri.opaque, 'blank')
  end

  test 'null uri should about:blank' do
    request = SSB::Request.new('GET', {'ssb_q'.taint => ''.taint}, cookie)
    assert_not_nil(request.uri)
    assert_instance_of(URI::Generic, request.uri)
    assert_equal(request.uri.scheme, 'about')
    assert_equal(request.uri.opaque, 'blank')

    request = SSB::Request.new('GET', {'ssb_q'.taint => nil}, cookie)
    assert_not_nil(request.uri)
    assert_instance_of(URI::Generic, request.uri)
    assert_equal(request.uri.scheme, 'about')
    assert_equal(request.uri.opaque, 'blank')
  end

  test 'test_request_should_success' do
    mock_server = MockServer.new
    assert(@request.execute)
    mock_server.shutdown
  end

  test 'test_request_get' do
    mock_server = MockServer.new
    request = SSB::Request.new('GET'.taint, request_params, cookie)
    response = request.execute
    assert_instance_of(Net::HTTPOK, response)
    assert(response.body =~ Regexp.new('It works by GET'))
    mock_server.shutdown
  end

  test 'test_request_post' do
    mock_server = MockServer.new
    request = SSB::Request.new('POST'.taint, request_params, cookie)
    response = request.execute
    assert_instance_of(Net::HTTPOK, response)
    assert(response.body =~ Regexp.new('It works by POST'))
    mock_server.shutdown
  end

  test 'no proxy' do
    http_class = @request.http_class
    connection = http_class.new("http://www.google.com")
    assert(!connection.proxy?)
  end

  test 'regular http proxy' do
    http_class = @request.http_class("http://my.proxy:1234")
    connection = http_class.new("http://www.google.com")
    assert(connection.proxy?)
    assert_equal(connection.proxy_port, 1234)
    assert_equal(connection.proxy_address, "my.proxy")
  end

  test 'http proxy with authorization' do
    http_class = @request.http_class("http://benjamin:secret999@my.proxy:1234")
    connection = http_class.new("http://www.google.com")
    assert(connection.proxy?)
    assert_equal(connection.proxy_user, "benjamin")
    assert_equal(connection.proxy_pass, "secret999")
  end

  test 'duplicate parameter keys' do
    params = {
      'ssb_q'.taint  => MockServer.uri.dup.taint,
      'p'.taint => WEBrick::HTTPUtils::FormData.new('foo'.taint, 'bar'.taint)
    }

    request = SSB::Request.new('GET'.taint, params, cookie)
    assert_equal("#{MockServer.uri}?p=foo&p=bar", request.uri.to_s)
  end
end
