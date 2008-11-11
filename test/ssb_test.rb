require File.expand_path(File.dirname(__FILE__) + '/test_helper')

unit_tests do
  def setup
    @savedir = Dir.pwd
    Dir.chdir 'public_html'
    @mock_server = MockServer.new
  end

  def teardown
    @mock_server.shutdown
    Dir.chdir @savedir
  end

  # launch ssb process via pipe
  def kick_ssb(method, query_string, postparams = nil)
    # CGI Parameters
    ENV['SERVER_NAME'] = 'localhost'
    ENV['SCRIPT_NAME'] = '/index.rbx'
    ENV['REQUEST_METHOD'] = method
    ENV['QUERY_STRING']   = query_string
    if postparams.nil?
      ENV['CONTENT_LENGTH'] = '0'
    else
      ENV['CONTENT_LENGTH'] = postparams.size.to_s
      ENV['CONTENT_TYPE'] = 'application/x-www-form-urlencoded'
    end
    open_type = {
      'GET'  => 'r',
      'POST' => 'r+',
    }

    ret = ''
    begin
      IO.popen('ruby -Ku index.rbx', open_type[method]) do |io|
        if method == 'POST'
          io.puts postparams unless postparams.nil?
          io.close_write
        end
        while read = io.gets
          ret.concat(read)
        end
      end
    rescue =>e
      ret = e.backtrace.to_s
    end
    ret
  end

  test 'ssb get local' do
    ret = kick_ssb('GET', "ssb_q=#{MockServer.uri}&uid=NULLGWDOCOMO")
    assert_match(/It works by GET/, ret)
  end

  test 'ssb get invalidhost' do
    # noname is invalid hostname
    ret = kick_ssb('GET', 'ssb_q=noname')
    exp = Regexp.union(
      /getaddrinfo: Name or service not known/,
      /getaddrinfo: nodename nor servname provided/)
    assert_match(exp, ret)
  end

  test 'ssb post local' do
    ret = kick_ssb('POST', '', "ssb_q=#{MockServer.uri}?param=test&uid=NULLGWDOCOMO")
    assert_match(/It works by POST/, ret)
  end

  test 'ssb post invalidhost' do
    # noname is invalid hostname
    ret = kick_ssb('POST', '', 'ssb_q=noname&param=test&uid=NULLGWDOCOMO')
    assert_match(/getaddrinfo: (?:nodename nor servname provided|Name or service not known)/, ret)
  end
end
