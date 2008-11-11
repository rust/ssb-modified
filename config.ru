# rackup で起動できる様に(実験的実装)
#   * libs/ssb/rack.rb: SSB::Application自体にcallメソッドを持たせる実装
#   * libs/rack/adapter/ssb.rb: Rack::Adapterを使ってオリジナルをラップする実装

require File.join(File.dirname(__FILE__), 'config', 'common.rb')
require 'ssb'
#require 'ssb/rack'
require 'rack/adapter/ssb'

# mod_passenger の場合の対応
#   * Rack::Lint::LintErrorは、deoployment環境かnone環境で実行すれば対処可能
#   * サーバ(ハンドラ)の判定方法は適当
unless ENV['RACK_ENV']
  use Rack::Static, :urls => ['/javascripts', '/stylesheets', '/emoji', '/images'], :root => 'public_html'
end

# run SSB::Application.new
run Rack::Adapter::SSB.new(SSB::Application.new)
