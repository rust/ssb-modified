# mock_server.rb - mock server
#
# Author:: MIZOGUCHI Coji <mizoguchi.coji at gmail.com>
# License:: Distributes under the same terms as Ruby
#
# $Id: mock_server.rb 2248 2007-12-01 11:46:12Z coji $
#
require 'webrick'

class MockServlet < WEBrick::HTTPServlet::AbstractServlet
  def initialize(server, *options)
  end

  def do_GET(req, res)
    @request_header = req.header
    res.body = 'It works by GET'
  end

  def do_POST(req, res)
    @request_header = req.header
    res.body = 'It works by POST'
  end
end

class MockServer
  def initialize
    @webserv = WEBrick::HTTPServer.new(MockServer.config)
    @server_thread = Thread.new do
      Thread.pass
      begin
        @webserv.mount('/', MockServlet)
        @webserv.start
      rescue => e
        puts e
      end
    end
  end

  def shutdown
    loop do
      sleep 1
      break if @webserv.status == :Running
    end
    @webserv.shutdown
    @server_thread.join
  end

  def self.uri
    URI.escape("http://#{self.config[:BindAddress]}:#{self.config[:Port]}/")
  end

  def self.config
    unless @conf
      @conf = {
        :BindAddress  => 'localhost',
        :Port         => 33223,
        :Logger       => WEBrick::Log.new(nil, WEBrick::Log::ERROR),
        :AccessLog    => [[IO.new(IO.sysopen('/dev/null', 'w')), WEBrick::AccessLog::COMMON_LOG_FORMAT]],
      }
    end
    @conf
  end
end

