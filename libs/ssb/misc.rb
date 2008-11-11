# misc.rb - miscellaneous
#
# Author:: MIZOGUCHI Coji <mizoguchi.coji at gmail.com>
# License:: Distributes under the same terms as Ruby
#
# $Id: misc.rb 16139 2008-07-23 12:59:54Z drry $
#
require 'ssb/ktai_spec'
require 'yaml'
require 'uri'

module SSB
  module Misc
    # ３桁ごとにカンマをつける
    def self.numeric(num)
      num.to_i.to_s.gsub(/\d(?=\d{3}+$)/, '\\0,')
    end

    # 端末情報の読み込み cookie or config.yaml
    def self.load_terminal_info(cookies)
      params = SSB::config['default'].dup

      cookies.each do |cookie|
        params[cookie.name.dup.untaint] = URI.unescape(cookie.value.untaint)
      end

      return SSB::KtaiSpec.new(params)
    end
  end
end
