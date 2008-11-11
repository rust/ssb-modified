#!/usr/bin/env ruby
# -*- ruby -*-
#
# Author:: MIZOGUCHI Coji <mizoguchi.coji at gmail.com>
# License:: Distributes under the same terms as Ruby
#
# $Id: index.rbx 2140 2007-11-29 04:09:28Z coji $
#
require '../config/common.rb'
require 'webrick/cgi'
require 'ssb.rb'

module SSB
  class WebrickCGIHandler < WEBrick::CGI
    def do_GET(req, res)
      app = ::SSB::Application.new
      app.run(req, res)
    end

    alias :do_POST :do_GET
  end
end

SSB::WebrickCGIHandler.new.start()

