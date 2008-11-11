# download_ktai_list.rb - download ke-tai list from http://ke-tai.org/
#
# Author:: MIZOGUCHI Coji <mizoguchi.coji at gmail.com>
# License:: Distribute under the same terms as Ruby
#
# $Id: download_qrcode_library.rb 2455 2007-12-04 19:27:37Z coji $
#
require 'config/common'
require 'open-uri'

uri = 'http://www.venus.dti.ne.jp/~swe/program/qrcode_rb0.50beta8.tar.gz'

open('vendor/qrcode.tar.gz', 'w') do |out|
  out.print open(uri).read()
end

`rm -Rf vendor/qrcode`
`tar --directory vendor -xzf vendor/qrcode.tar.gz`
`mv vendor/qrcode_rb0.50beta8 vendor/qrcode`
`rm vendor/qrcode.tar.gz`

