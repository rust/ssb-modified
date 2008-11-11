# SSBをRack::AdapterでRackに対応させる試み
require 'rubygems'
require 'rack'
require 'ostruct'
require 'webrick'

module Rack

  module Adapter

    class SSB
      def initialize(app)
        @app = app
      end

      def call(env)
        cgi_request = build_request(env)
        cgi_response = build_response
        result = @app.run(cgi_request, cgi_response)
        [200, cgi_response.header, (result || cgi_response.body)]
      end

      def build_request(env)
        request = Rack::Request.new(env)

        class << request

          def query
            Rack::Utils.parse_query(query_string)
          end

          alias_method :origin_cookies, :cookies
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

        request
      end

      def build_response
        ::OpenStruct.new(
          :body => '',
          :header => { 'Content-Type' => 'text/html; charset=UTF-8' }
        )
      end

    end

  end

end

