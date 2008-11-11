require 'webrick'
require 'optparse'

port = 10080
bind_address = '127.0.0.1'
cgi_mode = false

opt = OptionParser.new
opt.on('-p port', '--port port') {|v| port = v.to_i }
opt.on('--bind ip') {|v| bind_address = v }
opt.on('--cgi-mode') {|v| cgi_mode = true } # only for debugging?
opt.parse!(ARGV)

bindir = File.dirname(__FILE__)
docroot = File.expand_path(File.join(bindir, 'public_html'))
Dir.chdir(docroot)
require '../config/common.rb'
require 'ssb.rb'

srv = WEBrick::HTTPServer.new({
  :DocumentRoot => docroot,
  :BindAddress => bind_address,
  :Port => port,
})
trap("INT"){ srv.shutdown }

if cgi_mode
  srv.mount('/', WEBrick::HTTPServlet::CGIHandler, File.join(docroot, 'index.rbx'))
else
  srv.mount_proc('/') {|req, res|
    app = SSB::Application.new
    app.run(req, res)
  }
end

%w(javascripts stylesheets emoji images).each {|x|
    srv.mount("/#{x}/", WEBrick::HTTPServlet::FileHandler, File.join(docroot, x))
}
srv.mount_proc('/favicon.ico'){|req,res|}
srv.start

